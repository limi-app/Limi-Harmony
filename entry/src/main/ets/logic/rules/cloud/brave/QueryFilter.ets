import { BraveQueryRule, BraveQueryRuleJson, processQueryRules } from './QueryRules';

export class QueryFilterRuleKeys {
  static readonly RULES: string = 'cloud_brave_query_filter_rules';
  static readonly VERSION_HASH: string = 'cloud_brave_query_filter_version_hash';
}

export function parseQueryFilter(body: string): BraveQueryRule[] {
  const json = JSON.parse(body) as BraveQueryRuleJson[];
  const rules: BraveQueryRule[] = [];
  for (let i = 0; i < json.length; i++) {
    rules.push(BraveQueryRule.fromJson(json[i]));
  }
  return rules;
}

export function decodeQueryFilterRules(raw: string): BraveQueryRule[] {
  if (raw.length === 0) {
    return [];
  }
  return parseQueryFilter(raw);
}

export function processQueryFilter(url: string, rules: BraveQueryRule[]): string {
  return processQueryRules(url, rules);
}
