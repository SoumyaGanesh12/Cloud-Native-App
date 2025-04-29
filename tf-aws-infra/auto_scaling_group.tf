# Auto Scaling Group for the Web Application
resource "aws_autoscaling_group" "webapp_asg" {
  name = "csye6225-asg"

  # Initial number of instances to start with
  desired_capacity = var.asg_desired_capacity

  # Minimum number of instances to keep running at all times
  min_size = var.asg_min_size

  # Maximum number of instances allowed to scale up to
  max_size = var.asg_max_size

  # List of public subnet IDs where instances will be launched
  vpc_zone_identifier = aws_subnet.public_subnets[*].id

  # Type of health checks used (EC2 or ELB)
  # health_check_type = "EC2"
  # ASG listens to the ALB health check status of each instance (which uses /healthz)
  # terminates & replaces instances when they become unresponsive at the application level.
  health_check_type = "ELB"

  # Grace period (in seconds) to allow instance warm-up before health checks start
  health_check_grace_period = 300

  # Automatically terminate instances when the ASG is deleted
  force_delete = true

  # Register launched instances with this Target Group (used by ALB)
  target_group_arns = [
    aws_lb_target_group.webapp_tg.arn
  ]

  launch_template {
    id      = aws_launch_template.webapp_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "webapp-asg-instance"
    propagate_at_launch = true
  }

  # Ensure instances are created before destroying old ones (avoids downtime)
  lifecycle {
    create_before_destroy = true
  }

  # Ensure ALB listener is created before ASG (so it can attach properly)
  depends_on = [aws_lb_listener.webapp_listener]
}

# Scale-Up Policy (scale_up → scale out → add capacity)

resource "aws_autoscaling_policy" "scale_up" {
  name = "scale-up-policy"

  # Target Auto Scaling Group name
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name

  # Increase the number of instances by 1
  scaling_adjustment = 1

  # Scaling adjustment type: add or remove instances
  adjustment_type = "ChangeInCapacity"

  # Cooldown period (in seconds) before another scaling action can occur
  cooldown = 60
}

# CloudWatch Alarm to trigger the scale-up policy
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name = "cpu-utilization-high"

  # Trigger when CPU utilization is greater than threshold
  comparison_operator = "GreaterThanThreshold"

  # Number of periods (60s) over which data is compared
  evaluation_periods = 1

  # The metric being monitored
  metric_name = "CPUUtilization"

  # Namespace for EC2 metrics
  namespace = "AWS/EC2"

  # Evaluation period in seconds
  period = 60

  # Type of metric aggregation
  statistic = "Average"

  # Threshold for triggering scale-up
  threshold = var.scale_up_threshold

  # Description for the alarm
  alarm_description = "Trigger ASG scale up when average CPU > 5%"

  # Filter the metric by ASG name (important!)
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }

  # Action to take when alarm is triggered
  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

# Scale-Down Policy (scale_down → scale in → reduce capacity)

resource "aws_autoscaling_policy" "scale_down" {
  name = "scale-down-policy"

  # Target Auto Scaling Group name
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name

  # Decrease the number of instances by 1
  scaling_adjustment = -1

  # Scaling adjustment type: add or remove instances
  adjustment_type = "ChangeInCapacity"

  # Cooldown period (in seconds) before another scaling action can occur
  cooldown = 60
}

# CloudWatch Alarm to trigger the scale-down policy
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name = "cpu-utilization-low"

  # Trigger when CPU utilization is less than threshold
  comparison_operator = "LessThanThreshold"

  # Number of periods (60s) over which data is compared
  evaluation_periods = 1

  # The metric being monitored
  metric_name = "CPUUtilization"

  # Namespace for EC2 metrics
  namespace = "AWS/EC2"

  # Evaluation period in seconds
  period = 60

  # Type of metric aggregation
  statistic = "Average"

  # Threshold for triggering scale-down
  threshold = var.scale_down_threshold

  # Description for the alarm
  alarm_description = "Trigger ASG scale down when average CPU < 3%"

  # Filter the metric by ASG name (important!)
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }

  # Action to take when alarm is triggered
  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}
