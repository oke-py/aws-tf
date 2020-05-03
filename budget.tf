resource "aws_budgets_budget" "cost" {
  name              = "monthly-budget"
  budget_type       = "COST"
  limit_amount      = "30.0"
  limit_unit        = "USD"
  time_period_start = "2020-05-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["okepy.naoki@gmail.com"]
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
  }
}
