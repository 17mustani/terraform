provider "aws" {
  access_key = ""
  secret_key = ""
  region = ""
}

resource "aws_lunch_configuration" "as_conf" {
  name_prefix = "terraform_lc"
  image_id = "ami-8abbf2e9"
  instance_type = "t2.micro"
  security_groups = ["sg-016e0367"]
  key_name = "first-key"

  lifecycle {
      create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "auto_scaling" {
  name = "terraform-asg"
  launch_configuration = "${aws_launch_configuration.as_config.name}"
  min_size = 2
  max_size = 10
  availability_zones = ["ap-southeast-1b", "ap-southeast-1a"]
  target_group_arns = ["arn:aws:elasticloadbalancing:ap-southeast-1"]
}

resource "aws_autoscaling_policy" "cpu_load_policy_up" {
  name = "scale-up"
  policy_type = "StepScaling"
  estimated_instance_warmup = 60
  metric_aggregation_type = "Average"
  adjustment_type = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.auto_scaling.name}"

  step_adjustment {
    metric_intervel_lower_bound = 1.0
    scaling_adjustment = 1
  }
}

resource "aws_autoscaling_policy" "cpu_load_policy_down" {
  name = "scale-down"
  policy_type = "StepScaling"
  estimated_instance_warmup = 60
  metric_aggregation_type = "Average"
  adjustment_type = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.auto_scaling.name}"

  step_adjustment {
    metric_interval_lower_bound = 1.0
    scaling_adjustment = -1
  }
}
 
resource "aws_cloudwatch_metric_alarm" "cpu_load_alarm_up" {
  alarm_name = "alarm-up"
  comparision_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "70"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.auto_scaling.name}"
  }
  
  alarm_description = "This metric monitors ec2 cpu utilization >= 70"
  alarm_actions = ["${aws_autoscaling_policy.cpu_load_policy_up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "cpu_load_alarm_down" {
  alarm_name = "alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "20"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.auto_scaling.name}"
  }
  
  alarm_description = "This metric monitors ec2 cpu utilization <= 70"
  alarm_actions = ["${aws_autoscaling_policy.cpu_load_policy_down.arn}"]
}

