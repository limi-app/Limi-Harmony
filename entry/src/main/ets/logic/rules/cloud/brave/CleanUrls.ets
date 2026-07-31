import { BraveQueryRule, BraveQueryRuleJson, processQueryRules } from './QueryRules';

export class CleanUrlsRuleKeys {
  static readonly RULES: string = 'cloud_brave_clean_urls_rules';
  static readonly VERSION_HASH: string = 'cloud_brave_clean_urls_version_hash';
}

export function parseCleanUrls(body: string): BraveQueryRule[] {
  const json = JSON.parse(body) as BraveQueryRuleJson[];
  const rules: BraveQueryRule[] = [];
  for (let i = 0; i < json.length; i++) {
    rules.push(BraveQueryRule.fromJson(json[i]));
  }
  return rules;
}

export function decodeCleanUrlsRules(raw: string): BraveQueryRule[] {
  if (raw.length === 0) {
    return [];
  }
  return parseCleanUrls(raw);
}

export function processCleanUrls(url: string, rules: BraveQueryRule[]): string {
  return processQueryRules(url, rules);
}
