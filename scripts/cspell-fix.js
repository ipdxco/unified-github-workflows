#!/usr/bin/env node

const { readFileSync, writeFileSync } = require('fs');
const { execSync } = require('child_process');
const { fileURLToPath } = require('url');

const stdout = execSync('cspell lint --reporter @cspell/cspell-json-reporter --report typos --no-exit-code .');

const { issues } = JSON.parse(stdout.toString());

for (const issue of issues) {
    if (!issue.hasSimpleSuggestions || !issue.hasPreferredSuggestions) {
        console.debug(`Issue ${issue.text} has no simple, preferred suggestions`);
        continue;
    }

    let suggestion;
    for (const s of issue.suggestionsEx) {
        if (s.isPreferred) {
            suggestion = s;
            break;
        }
    }

    if (suggestion === undefined) {
        console.warn(`No preferred suggestion for ${issue.text}`);
        continue;
    }

    const word = suggestion.wordAdjustedToMatchCase ?? suggestion.word;
    const filePath = fileURLToPath(issue.uri);

    const content = readFileSync(filePath, 'utf8');
    writeFileSync(filePath, content.replace(issue.text, word));

    console.debug(`Replaced ${issue.text} with ${word} in ${filePath}`);
}
