#!/usr/bin/env node

const { readFileSync, writeFileSync } = require('fs');
const { execSync } = require('child_process');
const { fileURLToPath } = require('url');

const stdout = execSync('cspell lint --reporter @cspell/cspell-json-reporter --report typos --no-exit-code .');

const { issues } = JSON.parse(stdout.toString());

const seen = new Map();

for (const issue of issues) {
    if (!issue.hasSimpleSuggestions || !issue.hasPreferredSuggestions) {
        console.debug(`Issue ${issue.text} has no simple, preferred suggestions`);
        continue;
    }

    const filePath = fileURLToPath(issue.uri);
    const text = issue.text;

    if (!seen.has(filePath)) {
        seen.set(filePath, new Set());
    }

    if (seen.get(filePath).has(text)) {
        console.debug(`Skipping ${text} in ${filePath}`);
        continue;
    }

    seen.get(filePath).add(text);

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

    const content = readFileSync(filePath, 'utf8');
    writeFileSync(filePath, content.replaceAll(text, word));

    console.debug(`Replaced ${text} with ${word} in ${filePath}`);
}
