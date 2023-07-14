# Cloudwatch Rule
resource "aws_cloudwatch_event_rule" "lambda_trigger_rule" {
  name                = local.project_name
  description         = "Scrape NYT Election API for latest result dataset"
  schedule_expression = "rate(5 minutes)"
  tags                = local.project_tags
}

# Cloudwatch Rule Trigger
resource "aws_cloudwatch_event_target" "lambda" {
  arn  = aws_lambda_function.election_scraper.arn
  rule = aws_cloudwatch_event_rule.lambda_trigger_rule.name
  input = jsonencode({
    scrapeUrl = "https://static01.nyt.com/elections-assets/2020/data/api/2020-11-03/national-map-page/national/president.json",
    timeout   = 10000
  })
}

# Cloudwatch Rule Permission
resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.election_scraper.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_trigger_rule.arn
}
