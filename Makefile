.PHONY: test-issue-headless test-issue-headed test-tags-headless test-tags-headed

SOURCE_ENV = set -a && . .env && set +a

test-issue-headless:
	@echo "🚀 Starting Agentic UI Test Execution (Headless)..."
	@$(SOURCE_ENV) && ./helper/agent-logic.sh "$$(echo $$XRAY_ISSUE_KEY | tr ',' ' ')" $$BASE_URL HEADLESS
	@echo "✅ Allure report updated: allure-report/"
	@echo "📊 To open the report in your browser, run: npx allure open allure-report"

test-issue-headed:
	@echo "🚀 Starting Agentic UI Test Execution (Headed)..."
	@$(SOURCE_ENV) && ./helper/agent-logic.sh "$$(echo $$XRAY_ISSUE_KEY | tr ',' ' ')" $$BASE_URL HEADED
	@echo "✅ Allure report updated: allure-report/"
	@echo "📊 To open the report in your browser, run: npx allure open allure-report"

test-tags-headless:
	@echo "🚀 Starting Agentic UI Test Execution (Headless)..."
	@$(SOURCE_ENV) && ./helper/agent-logic.sh "$$(echo $$XRAY_TAGS | tr ',' ' ')" $$BASE_URL HEADLESS
	@echo "✅ Allure report updated: allure-report/"
	@echo "📊 To open the report in your browser, run: npx allure open allure-report"

test-tags-headed:
	@echo "🚀 Starting Agentic UI Test Execution (Headed)..."
	@$(SOURCE_ENV) && ./helper/agent-logic.sh "$$(echo $$XRAY_TAGS | tr ',' ' ')" $$BASE_URL HEADED
	@echo "✅ Allure report updated: allure-report/"
	@echo "📊 To open the report in your browser, run: npx allure open allure-report"
