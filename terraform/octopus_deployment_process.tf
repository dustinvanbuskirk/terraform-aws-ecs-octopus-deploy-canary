# Deployment Process - Inline Steps (No Process Template)
# Note: Process templates are not yet supported in the new octopusdeploy_process resource
# This defines all canary deployment steps inline
resource "octopusdeploy_deployment_process" "ecs_canary" {
  count = (!local.project_exists || var.create_deployment_process) ? 1 : 0
  
  project_id = local.project_id
  space_id   = local.octopus_space_id

  # Step 1: Get Current Stable Stack
  step {
    name          = "Get Current Stable Stack"
    condition     = "Success"
    start_trigger = "StartAfterPrevious"

    run_script_action {
      name           = "Get Stable Stack Tag"
      run_on_server  = true
      worker_pool_id = var.octopus_worker_pool_id
      script_syntax  = "Bash"
      script_body    = <<-EOT
        CLUSTER_NAME=$(echo "#{ECS.ClusterArn}" | awk -F'/' '{print $NF}')
        SERVICE_ARN="arn:aws:ecs:#{AWS.Region}:$(aws sts get-caller-identity --query Account --output text):service/$CLUSTER_NAME/#{ECS.ServiceName}"
        echo "Service ARN: $SERVICE_ARN"
        STACK=$(aws ecs list-tags-for-resource --resource-arn "$SERVICE_ARN" --region #{AWS.Region} | jq -r '.tags[] | select(.key == "StableStack") | .value')
        echo "Current stable stack: $STACK"
        set_octopusvariable "StableStack" "$STACK"
        TASKSET_ARN=$(aws ecs describe-services --cluster #{ECS.ClusterArn} --services #{ECS.ServiceName} --region #{AWS.Region} | jq -r ".services[0].taskSets[] | select(.externalId == \"Octopus$${STACK}Stack\") | .taskSetArn")
        echo "Stable task set ARN: $TASKSET_ARN"
        set_octopusvariable "StableTaskSetArn" "$TASKSET_ARN"
        STABLE_TASK_DEF=$(aws ecs describe-task-sets --cluster #{ECS.ClusterArn} --service #{ECS.ServiceName} --task-sets "$TASKSET_ARN" --region #{AWS.Region} | jq -r '.taskSets[0].taskDefinition')
        echo "Stable task definition: $STABLE_TASK_DEF"
        set_octopusvariable "StableTaskDefinition" "$STABLE_TASK_DEF"
      EOT
      
      properties = {
        "Octopus.Action.Aws.AssumeRole"              = "False"
        "Octopus.Action.Aws.Region"                  = var.aws_region
        "Octopus.Action.AwsAccount.UseInstanceRole"  = "False"
        "Octopus.Action.AwsAccount.Variable"         = local.aws_account_id
      }
    }
  }

  # Step 2: Create New Task Definition
  step {
    name          = "Create New Task Definition"
    condition     = "Success"
    start_trigger = "StartAfterPrevious"

    run_script_action {
      name           = "Register Task Definition"
      run_on_server  = true
      worker_pool_id = var.octopus_worker_pool_id
      script_syntax  = "Bash"
      script_body    = <<-EOT
        TASK_FAMILY="${var.task_family != "" ? var.task_family : var.service_name}"
        case "#{Octopus.Environment.Name}" in
          "Development") TASK_FAMILY="${var.task_family != "" ? var.task_family : var.service_name}-development" ;;
          "Test") TASK_FAMILY="${var.task_family != "" ? var.task_family : var.service_name}-test" ;;
          "Production") TASK_FAMILY="${var.task_family != "" ? var.task_family : var.service_name}-production" ;;
        esac
        echo "Using task family: $TASK_FAMILY"
        cat > task-def.json <<TASKDEF
        {"family":"$TASK_FAMILY","networkMode":"awsvpc","requiresCompatibilities":["FARGATE"],"cpu":"256","memory":"512","containerDefinitions":[{"name":"mycontainer","image":"${var.container_image}:latest","cpu":256,"memory":512,"memoryReservation":128,"essential":true,"environment":[{"name":"APPVERSION","value":"#{Octopus.Release.Number}"},{"name":"ENVIRONMENT","value":"#{Octopus.Environment.Name}"}],"portMappings":[{"containerPort":4000,"hostPort":4000,"protocol":"tcp"}]}]}
        TASKDEF
        NEW_TASK_DEF=$(aws ecs register-task-definition --cli-input-json file://task-def.json --region #{AWS.Region} | jq -r '.taskDefinition.taskDefinitionArn')
        echo "New task definition: $NEW_TASK_DEF"
        set_octopusvariable "NewTaskDefinition" "$NEW_TASK_DEF"
      EOT
      
      properties = {
        "Octopus.Action.Aws.AssumeRole"              = "False"
        "Octopus.Action.Aws.Region"                  = var.aws_region
        "Octopus.Action.AwsAccount.UseInstanceRole"  = "False"
        "Octopus.Action.AwsAccount.Variable"         = local.aws_account_id
      }
    }
  }

  # Step 3: Create Canary Task Set (DO NOT DELETE STABLE)
  step {
    name          = "Create Canary Task Set"
    condition     = "Success"
    start_trigger = "StartAfterPrevious"

    run_script_action {
      name           = "Create Canary Task Set"
      run_on_server  = true
      worker_pool_id = var.octopus_worker_pool_id
      script_syntax  = "Bash"
      script_body    = <<-EOT
        STABLE_STACK="#{Octopus.Action[Get Stable Stack Tag].Output.StableStack}"
        echo "Current stable stack: $STABLE_STACK"
        
        # Determine which stack is canary (opposite of stable)
        if [ "$STABLE_STACK" == "Blue" ]; then
          CANARY_EXTERNAL_ID="OctopusGreenStack"
          CANARY_TARGET_GROUP="#{ECS.GreenTargetGroupArn}"
          echo "Canary will be: Green"
        else
          CANARY_EXTERNAL_ID="OctopusBlueStack"
          CANARY_TARGET_GROUP="#{ECS.BlueTargetGroupArn}"
          echo "Canary will be: Blue"
        fi
        
        # Check if canary task set already exists and delete it
        CANARY_TASKSET_ID=$(aws ecs describe-services --cluster #{ECS.ClusterArn} --services #{ECS.ServiceName} --region #{AWS.Region} | jq -r ".services[0].taskSets[] | select(.externalId == \"$CANARY_EXTERNAL_ID\") | .id")
        if [ ! -z "$CANARY_TASKSET_ID" ] && [ "$CANARY_TASKSET_ID" != "null" ]; then
          echo "Deleting existing canary task set: $CANARY_TASKSET_ID"
          aws ecs delete-task-set --cluster #{ECS.ClusterArn} --service #{ECS.ServiceName} --task-set "$CANARY_TASKSET_ID" --region #{AWS.Region} --force || true
          echo "Waiting for task set deletion..."
          sleep 15
        fi
        
        echo "Creating canary task set with new task definition..."
        aws ecs create-task-set \
          --cluster #{ECS.ClusterArn} \
          --service #{ECS.ServiceName} \
          --task-definition "#{Octopus.Action[Register Task Definition].Output.NewTaskDefinition}" \
          --external-id "$CANARY_EXTERNAL_ID" \
          --launch-type FARGATE \
          --region #{AWS.Region} \
          --network-configuration "awsvpcConfiguration={subnets=[#{ECS.SubnetIds}],securityGroups=[#{ECS.SecurityGroupIds}],assignPublicIp=ENABLED}" \
          --load-balancers "targetGroupArn=$CANARY_TARGET_GROUP,containerName=mycontainer,containerPort=4000" \
          --scale "unit=PERCENT,value=100"
        
        # Update testing listener to point to canary
        aws elbv2 modify-rule \
          --rule-arn "#{ECS.TestingListenerRuleArn}" \
          --region #{AWS.Region} \
          --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$CANARY_TARGET_GROUP\"}]"
        
        echo "Canary task set created successfully"
        set_octopusvariable "CanaryExternalId" "$CANARY_EXTERNAL_ID"
      EOT
      
      properties = {
        "Octopus.Action.Aws.AssumeRole"              = "False"
        "Octopus.Action.Aws.Region"                  = var.aws_region
        "Octopus.Action.AwsAccount.UseInstanceRole"  = "False"
        "Octopus.Action.AwsAccount.Variable"         = local.aws_account_id
      }
    }
  }

  # Step 4: Wait for Canary Tasks Healthy
  step {
    name          = "Wait for Canary Tasks Healthy"
    condition     = "Success"
    start_trigger = "StartAfterPrevious"

    run_script_action {
      name           = "Check Canary Task Health"
      run_on_server  = true
      worker_pool_id = var.octopus_worker_pool_id
      script_syntax  = "Bash"
      script_body    = <<-EOT
        STABLE_STACK="#{Octopus.Action[Get Stable Stack Tag].Output.StableStack}"
        if [ "$STABLE_STACK" == "Blue" ]; then
          CANARY_TARGET_GROUP="#{ECS.GreenTargetGroupArn}"
        else
          CANARY_TARGET_GROUP="#{ECS.BlueTargetGroupArn}"
        fi
        echo "Waiting for canary tasks to be healthy..."
        MAX_WAIT=300
        ELAPSED=0
        while [ $ELAPSED -lt $MAX_WAIT ]; do
          HEALTHY=$(aws elbv2 describe-target-health --target-group-arn "$CANARY_TARGET_GROUP" --region #{AWS.Region} | jq -r '.TargetHealthDescriptions[] | select(.TargetHealth.State == "healthy") | .Target.Id' | wc -l)
          if [ "$HEALTHY" -ge "1" ]; then
            echo "Canary tasks are healthy"
            exit 0
          fi
          sleep 10
          ELAPSED=$((ELAPSED + 10))
        done
        echo "Timeout waiting for healthy tasks"
        exit 1
      EOT
      
      properties = {
        "Octopus.Action.Aws.AssumeRole"              = "False"
        "Octopus.Action.Aws.Region"                  = var.aws_region
        "Octopus.Action.AwsAccount.UseInstanceRole"  = "False"
        "Octopus.Action.AwsAccount.Variable"         = local.aws_account_id
      }
    }
  }

  # Step 5: Manual Approval - Start Canary
  step {
    name          = "Manual Approval - Start Canary"
    condition     = "Success"
    start_trigger = "StartAfterPrevious"

    manual_intervention_action {
      name          = "Approve Canary Start"
      instructions  = "Canary deployment is ready. Approve to route 10% of traffic to the new version."
      responsible_teams = "teams-everyone"
    }
  }

  # Step 6: Route Initial Traffic (10%)
  step {
    name          = "Route 10% Traffic to Canary"
    condition     = "Success"
    start_trigger = "StartAfterPrevious"

    run_script_action {
      name           = "Update to 10% Canary Traffic"
      run_on_server  = true
      worker_pool_id = var.octopus_worker_pool_id
      script_syntax  = "Bash"
      script_body    = <<-EOT
        STABLE_STACK="#{Octopus.Action[Get Stable Stack Tag].Output.StableStack}"
        CANARY_WEIGHT=10
        STABLE_WEIGHT=$((100 - CANARY_WEIGHT))
        if [ "$STABLE_STACK" == "Blue" ]; then
          STABLE_TG="#{ECS.BlueTargetGroupArn}"
          CANARY_TG="#{ECS.GreenTargetGroupArn}"
        else
          STABLE_TG="#{ECS.GreenTargetGroupArn}"
          CANARY_TG="#{ECS.BlueTargetGroupArn}"
        fi
        aws elbv2 modify-rule --rule-arn #{ECS.ListenerRuleArn} --region #{AWS.Region} --actions "[{\"Type\":\"forward\",\"Order\":1,\"ForwardConfig\":{\"TargetGroups\":[{\"Weight\":$STABLE_WEIGHT,\"TargetGroupArn\":\"$STABLE_TG\"},{\"Weight\":$CANARY_WEIGHT,\"TargetGroupArn\":\"$CANARY_TG\"}]}}]"
        echo "Traffic split: Stable $${STABLE_WEIGHT}% Canary $${CANARY_WEIGHT}%"
      EOT
      
      properties = {
        "Octopus.Action.Aws.AssumeRole"              = "False"
        "Octopus.Action.Aws.Region"                  = var.aws_region
        "Octopus.Action.AwsAccount.UseInstanceRole"  = "False"
        "Octopus.Action.AwsAccount.Variable"         = local.aws_account_id
      }
    }
  }

  # Step 7: Route 50% Traffic
  step {
    name          = "Route 50% Traffic to Canary"
    condition     = "Success"
    start_trigger = "StartAfterPrevious"

    run_script_action {
      name           = "Update to 50% Canary Traffic"
      run_on_server  = true
      worker_pool_id = var.octopus_worker_pool_id
      script_syntax  = "Bash"
      script_body    = <<-EOT
        STABLE_STACK="#{Octopus.Action[Get Stable Stack Tag].Output.StableStack}"
        CANARY_WEIGHT=50
        STABLE_WEIGHT=$((100 - CANARY_WEIGHT))
        if [ "$STABLE_STACK" == "Blue" ]; then
          STABLE_TG="#{ECS.BlueTargetGroupArn}"
          CANARY_TG="#{ECS.GreenTargetGroupArn}"
        else
          STABLE_TG="#{ECS.GreenTargetGroupArn}"
          CANARY_TG="#{ECS.BlueTargetGroupArn}"
        fi
        aws elbv2 modify-rule --rule-arn #{ECS.ListenerRuleArn} --region #{AWS.Region} --actions "[{\"Type\":\"forward\",\"Order\":1,\"ForwardConfig\":{\"TargetGroups\":[{\"Weight\":$STABLE_WEIGHT,\"TargetGroupArn\":\"$STABLE_TG\"},{\"Weight\":$CANARY_WEIGHT,\"TargetGroupArn\":\"$CANARY_TG\"}]}}]"
        echo "Traffic split: Stable $${STABLE_WEIGHT}% Canary $${CANARY_WEIGHT}%"
      EOT
      
      properties = {
        "Octopus.Action.Aws.AssumeRole"              = "False"
        "Octopus.Action.Aws.Region"                  = var.aws_region
        "Octopus.Action.AwsAccount.UseInstanceRole"  = "False"
        "Octopus.Action.AwsAccount.Variable"         = local.aws_account_id
      }
    }
  }

  # Step 8: Manual Decision - Complete or Rollback
  step {
    name          = "Manual Decision - Complete or Rollback"
    condition     = "Success"
    start_trigger = "StartAfterPrevious"

    manual_intervention_action {
      name          = "Approve Complete Cutover"
      instructions  = "Canary is receiving 50% traffic. Approve to route 100% traffic (complete cutover) or use guided failure to rollback."
      responsible_teams = "teams-everyone"
    }
  }

  # Step 9: Complete Cutover and Clean Up Old Stable
  step {
    name          = "Complete Cutover to Canary"
    condition     = "Success"
    start_trigger = "StartAfterPrevious"

    run_script_action {
      name           = "Route 100% to Canary"
      run_on_server  = true
      worker_pool_id = var.octopus_worker_pool_id
      script_syntax  = "Bash"
      script_body    = <<-EOT
        STABLE_STACK="#{Octopus.Action[Get Stable Stack Tag].Output.StableStack}"
        if [ "$STABLE_STACK" == "Blue" ]; then
          NEW_STABLE_TG="#{ECS.GreenTargetGroupArn}"
          OLD_STABLE_TG="#{ECS.BlueTargetGroupArn}"
          NEW_STABLE_STACK="Green"
          OLD_STABLE_EXTERNAL_ID="OctopusBlueStack"
        else
          NEW_STABLE_TG="#{ECS.BlueTargetGroupArn}"
          OLD_STABLE_TG="#{ECS.GreenTargetGroupArn}"
          NEW_STABLE_STACK="Blue"
          OLD_STABLE_EXTERNAL_ID="OctopusGreenStack"
        fi
        
        echo "Routing 100% to $NEW_STABLE_STACK"
        aws elbv2 modify-rule --rule-arn #{ECS.ListenerRuleArn} --region #{AWS.Region} --actions "[{\"Type\":\"forward\",\"Order\":1,\"ForwardConfig\":{\"TargetGroups\":[{\"Weight\":0,\"TargetGroupArn\":\"$OLD_STABLE_TG\"},{\"Weight\":100,\"TargetGroupArn\":\"$NEW_STABLE_TG\"}]}}]"
        
        # Update the StableStack tag
        CLUSTER_NAME=$(echo "#{ECS.ClusterArn}" | awk -F'/' '{print $NF}')
        SERVICE_ARN="arn:aws:ecs:#{AWS.Region}:$(aws sts get-caller-identity --query Account --output text):service/$CLUSTER_NAME/#{ECS.ServiceName}"
        aws ecs tag-resource --resource-arn "$SERVICE_ARN" --region #{AWS.Region} --tags key=StableStack,value=$NEW_STABLE_STACK
        
        echo "Cutover complete - $NEW_STABLE_STACK is now stable"
        
        # NOW delete the old stable task set (safe to do after cutover)
        echo "Cleaning up old stable task set..."
        OLD_TASKSET_ID=$(aws ecs describe-services --cluster #{ECS.ClusterArn} --services #{ECS.ServiceName} --region #{AWS.Region} | jq -r ".services[0].taskSets[] | select(.externalId == \"$OLD_STABLE_EXTERNAL_ID\") | .id")
        if [ ! -z "$OLD_TASKSET_ID" ] && [ "$OLD_TASKSET_ID" != "null" ]; then
          echo "Deleting old stable task set: $OLD_TASKSET_ID"
          aws ecs delete-task-set --cluster #{ECS.ClusterArn} --service #{ECS.ServiceName} --task-set "$OLD_TASKSET_ID" --region #{AWS.Region} --force || true
          echo "Old task set deleted"
        fi
      EOT
      
      properties = {
        "Octopus.Action.Aws.AssumeRole"              = "False"
        "Octopus.Action.Aws.Region"                  = var.aws_region
        "Octopus.Action.AwsAccount.UseInstanceRole"  = "False"
        "Octopus.Action.AwsAccount.Variable"         = local.aws_account_id
      }
    }
  }

  # Step 10: Rollback on Failure
  step {
    condition     = "Failure"
    name          = "Rollback to Stable"
    start_trigger = "StartAfterPrevious"

    run_script_action {
      name           = "Emergency Rollback to Stable Stack"
      run_on_server  = true
      worker_pool_id = var.octopus_worker_pool_id
      script_syntax  = "Bash"
      script_body    = <<-EOT
        echo "INITIATING EMERGENCY ROLLBACK"
        STABLE_STACK="#{Octopus.Action[Get Stable Stack Tag].Output.StableStack}"
        if [ -z "$STABLE_STACK" ] || [ "$STABLE_STACK" == "null" ]; then
          CLUSTER_NAME=$(echo "#{ECS.ClusterArn}" | awk -F'/' '{print $NF}')
          SERVICE_ARN="arn:aws:ecs:#{AWS.Region}:$(aws sts get-caller-identity --query Account --output text):service/$CLUSTER_NAME/#{ECS.ServiceName}"
          STABLE_STACK=$(aws ecs list-tags-for-resource --resource-arn "$SERVICE_ARN" --region #{AWS.Region} | jq -r '.tags[] | select(.key == "StableStack") | .value')
          if [ -z "$STABLE_STACK" ]; then
            STABLE_STACK="Blue"
          fi
        fi
        if [ "$STABLE_STACK" == "Blue" ]; then
          STABLE_TG="#{ECS.BlueTargetGroupArn}"
          CANARY_TG="#{ECS.GreenTargetGroupArn}"
        else
          STABLE_TG="#{ECS.GreenTargetGroupArn}"
          CANARY_TG="#{ECS.BlueTargetGroupArn}"
        fi
        aws elbv2 modify-rule --rule-arn #{ECS.ListenerRuleArn} --region #{AWS.Region} --actions "[{\"Type\":\"forward\",\"Order\":1,\"ForwardConfig\":{\"TargetGroups\":[{\"Weight\":100,\"TargetGroupArn\":\"$STABLE_TG\"},{\"Weight\":0,\"TargetGroupArn\":\"$CANARY_TG\"}]}}]"
        echo "ROLLBACK COMPLETE - All traffic restored to $STABLE_STACK"
      EOT
      
      properties = {
        "Octopus.Action.Aws.AssumeRole"              = "False"
        "Octopus.Action.Aws.Region"                  = var.aws_region
        "Octopus.Action.AwsAccount.UseInstanceRole"  = "False"
        "Octopus.Action.AwsAccount.Variable"         = local.aws_account_id
      }
    }
  }
}