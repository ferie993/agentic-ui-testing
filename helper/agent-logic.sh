#!/bin/bash
# helper/agent-logic.sh - Intelligent Agent Logic with Refined Precision

TAGS="$1"
BASE_URL="$2"
MODE="$3"

./helper/runner.sh "$TAGS" "$BASE_URL" "$MODE"
EXIT_CODE=$?

if [ $EXIT_CODE -eq 2 ] || [ $EXIT_CODE -eq 4 ]; then
    echo "🤖 [AI] Cache Miss/Stale detected. Generating intelligent precise scripts..."
    
    if [ -f .playwright-cli/stale_files.txt ]; then
        STALE_FILES=$(cat .playwright-cli/stale_files.txt)
        TARGET_PROMPT="the following specific feature files: $STALE_FILES"
    else
        TARGET_PROMPT="missing feature files in 'test/' matching tag $TAGS"
    fi

    # Run Gemini with error checking
    gemini --prompt "PRECISION PROTOCOL: 1. Identify $TARGET_PROMPT. 2. For EACH, write a STANDALONE bash script to 'step-definitions/<basename>-step.sh'. 3. STANDALONE: Start with '#!/bin/bash', 'set -e', then 'npx playwright-cli open \"$BASE_URL\" \$HEADED_FLAG > /dev/null 2>&1'. USE 'run-code' for ALL interactions. CRITICAL: When locating elements to click by text, filter for visible elements (e.g., \`locator('visible=true')\`). IF the text is an option in a dropdown (e.g. \"Paling lama\"), you MUST use \`selectOption\` on the parent select with the matched option's value. ONLY call selectOption if the current value is different. Example robust interaction: 'npx playwright-cli run-code \"async page => { const select = page.locator(\\'select\\').filter({ hasText: new RegExp(\\'Paling lama\\', \\'i\\') }).first(); if (await select.count() > 0) { const val = await select.locator(\\'option\\').filter({ hasText: new RegExp(\\'Paling lama\\', \\'i\\') }).first().getAttribute(\\'value\\'); const currentVal = await select.evaluate(s => s.value); if (val !== currentVal) await select.selectOption(val); } else { await page.locator(\\'text=Paling lama\\').locator(\\'visible=true\\').first().click(); } }\" > /dev/null 2>&1'. DO NOT use 'playwright-cli fill' or 'playwright-cli click' with CSS selectors. ALWAYS append '> /dev/null 2>&1' to run-code commands. ADD 'sleep 3' before assertions to allow React/Next.js to render. ADD A COMMENT before each Playwright interaction command with the exact text of the Gherkin step it implements (e.g., '# Given pengguna berada pada halaman utama'). 4. INTELLIGENT ASSERTIONS: Read the 'Then' step carefully. 
    A) If the step contains QUOTED TEXT: Extract exact string. Use Playwright to check for absolute equality of text lines. Use: 'OUTPUT=\$(npx playwright-cli run-code \"async page => { const expected = \\'QUOTED_TEXT_HERE\\'; const text = await page.evaluate(() => document.body.innerText); const lines = text.split(/\\r?\\n/).map(s => s.trim()).filter(s => s.length > 0); const exists = lines.some(l => l === expected); if (!exists) { const actual = lines.reduce((best, l) => { const ew = expected.toLowerCase().split(/\\W+/).filter(Boolean); const lw = l.toLowerCase().split(/\\W+/).filter(Boolean); const overlap = ew.filter(w => lw.includes(w)).length; return (overlap > best.max) ? { t: l, max: overlap } : best; }, { t: \\'Text not found\\', max: 0 }).t; return \\'FAIL\\' + \\'URE_DETECTED: ACTUAL_VALUE:\\' + actual; } }\" 2>&1); if echo \"\$OUTPUT\" | grep -q \"FAILURE_DETECTED\"; then echo \"Assertion Failed: Expected exact text \\'QUOTED_TEXT_HERE\\'\"; echo \"Actual text found: \$(echo \"\$OUTPUT\" | grep -m 1 -o \"ACTUAL_VALUE:.*\" | cut -d: -f2- | sed \\'s/\"//g\\')\"; npx playwright-cli screenshot --filename=allure-results/<basename>-screenshot.png > /dev/null 2>&1; npx playwright-cli close > /dev/null 2>&1; exit 1; fi'
    B) If the step describes a STATE: Verify visibility. Use: 'if ! npx playwright-cli eval \"document.body.innerText.includes(\\'System Overview\\')\" | grep -q \"true\"; then echo \"Assertion Failed: Expected state/element was not visible in the DOM.\"; npx playwright-cli screenshot --filename=allure-results/<basename>-screenshot.png > /dev/null 2>&1; npx playwright-cli close > /dev/null 2>&1; exit 1; fi'
    C) If the step mentions SORTING (e.g., 'Ascending' or 'Descending'): Extract dates and verify order. Use: 'OUTPUT=\$(npx playwright-cli run-code \"async page => { const order = \\'ascending\\'; /* Use ascending or descending based on step */ const text = await page.evaluate(() => document.body.innerText); const dateRegex = /\\\\d{2} [A-Za-z]+ \\\\d{4}/g; const dates = [...text.matchAll(dateRegex)].map(m => { const d = new Date(m[0].replace(/Januari/i, \\'Jan\\').replace(/Februari/i, \\'Feb\\').replace(/Maret/i, \\'Mar\\').replace(/April/i, \\'Apr\\').replace(/Mei/i, \\'May\\').replace(/Juni/i, \\'Jun\\').replace(/Juli/i, \\'Jul\\').replace(/Agustus/i, \\'Aug\\').replace(/September/i, \\'Sep\\').replace(/Oktober/i, \\'Oct\\').replace(/November/i, \\'Nov\\').replace(/Desember/i, \\'Dec\\')); return d.getTime(); }); if(dates.length < 2) return \\'PASS\\'; let isSorted = true; for(let i=1; i<dates.length; i++) { if(order.toLowerCase() === \\'ascending\\') { if(dates[i] < dates[i-1]) isSorted = false; } else { if(dates[i] > dates[i-1]) isSorted = false; } } if(!isSorted) return \\'FAILED_SORT: Dates are not sorted \\' + order; return \\'PASS\\'; }\" 2>&1); if echo \"\$OUTPUT\" | head -n 2 | grep -q \"FAILED_SORT\"; then echo \"Assertion Failed: Dates were not sorted correctly\"; npx playwright-cli screenshot --filename=allure-results/<basename>-screenshot.png > /dev/null 2>&1; npx playwright-cli close > /dev/null 2>&1; exit 1; fi'
    5. SUCCESS CLEANUP: End script with standard screenshot to 'allure-results/' (e.g., npx playwright-cli screenshot --filename=allure-results/<basename>-screenshot.png > /dev/null 2>&1) and close. 6. Make executable. 7. OUTPUT: Be extremely concise. Just list created files. (max 1-2 lines)" --yolo 2>/dev/null || { echo "❌ [AI] Generation failed due to API or Network error."; exit 1; }
    
    if [ $EXIT_CODE -eq 4 ]; then
        # Partial stale: only execute the updated ones to complete the report
        echo "🤖 [AI] Executing updated scenarios to complete report..."
        ./helper/runner.sh "$STALE_FILES" "$BASE_URL" "$MODE"
    else
        # Full stale (EXIT_CODE 2): execute all with tags to ensure clean start and tagging
        echo "🤖 [AI] Executing full suite for tag: $TAGS"
        ./helper/runner.sh "$TAGS" "$BASE_URL" "$MODE"
    fi
elif [ $EXIT_CODE -eq 3 ]; then
    echo "🤖 [AI] XRAY Fallback..."
    gemini --prompt "PRECISION PROTOCOL: 1. Fetch from XRAY. 2. Write STANDALONE scripts. 3. Use QUOTED TEXT for exact character match, STATE detection for general descriptions, or SORTING rules if the step mentions 'Ascending'/'Descending'. CRITICAL: When locating elements to click by text, filter for visible elements (e.g., \`locator('visible=true')\`). IF the text is an option in a dropdown (e.g. \"Paling lama\"), you MUST use \`selectOption\` on the parent select with the matched option's value. ONLY call selectOption if the current value is different. Example robust interaction: 'npx playwright-cli run-code \"async page => { const select = page.locator(\\'select\\').filter({ hasText: new RegExp(\\'Paling lama\\', \\'i\\') }).first(); if (await select.count() > 0) { const val = await select.locator(\\'option\\').filter({ hasText: new RegExp(\\'Paling lama\\', \\'i\\') }).first().getAttribute(\\'value\\'); const currentVal = await select.evaluate(s => s.value); if (val !== currentVal) await select.selectOption(val); } else { await page.locator(\\'text=Paling lama\\').locator(\\'visible=true\\').first().click(); } }\" > /dev/null 2>&1'. ADD 'sleep 3' before assertions. ADD A COMMENT before each Playwright interaction command with the exact text of the Gherkin step it implements (e.g., '# Given pengguna berada pada halaman utama'). 4. If failure: SCREENSHOT -> CLOSE -> EXIT 1. 5. End with standard screenshot to 'allure-results/' (e.g., npx playwright-cli screenshot --filename=allure-results/<basename>-screenshot.png > /dev/null 2>&1) and close. 6. Make executable. 7. OUTPUT: Be extremely concise. Just list created files. (max 1-2 lines)" --yolo 2>/dev/null || { echo "❌ [AI] XRAY Fetching failed."; exit 1; }
    ./helper/runner.sh "$TAGS" "$BASE_URL" "$MODE"
elif [ $EXIT_CODE -ne 0 ]; then
    exit $EXIT_CODE
fi

npx allure generate allure-results -o allure-report --clean > /dev/null 2>&1
