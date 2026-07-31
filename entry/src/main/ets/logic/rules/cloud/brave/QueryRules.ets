import { ParsedUrl, parseUrl, rebuildUrlWithQuery } from '../../../../utils/LinkExtractor';
import { UrlPattern } from './UrlPattern';

/**
 * Brave Clean Urls 与 Query Filter 共用的规则数据结构。
 * include/exclude 为 URL 模式列表，params 为要剔除的查询参数名列表。
 */
export class BraveQueryRule {
  include: string[] = [];
  exclude: string[] = [];
  params: string[] = [];
  compiledInclude: UrlPattern[] = [];
  compiledExclude: UrlPattern[] = [];

  static fromJson(obj: BraveQueryRuleJson): BraveQueryRule {
    const rule = new BraveQueryRule();
    rule.include = obj.include !== undefined ? obj.include : [];
    rule.exclude = obj.exclude !== undefined ? obj.exclude : [];
    rule.params = obj.params !== undefined ? obj.params : [];
    rule.compiledInclude = compilePatterns(rule.include);
    rule.compiledExclude = compilePatterns(rule.exclude);
    return rule;
  }
}

export interface BraveQueryRuleJson {
  include?: string[];
  exclude?: string[];
  params?: string[];
}

export function compilePatterns(patterns: string[]): UrlPattern[] {
  const compiled: UrlPattern[] = [];
  for (let i = 0; i < patterns.length; i++) {
    compiled.push(UrlPattern.compile(patterns[i]));
  }
  return compiled;
}

/**
 * 判断 URL 是否匹配规则：include 命中至少一个且 exclude 一个都不命中。
 */
export function ruleMatches(url: ParsedUrl, include: UrlPattern[], exclude: UrlPattern[]): boolean {
  let includeMatch = false;
  for (let i = 0; i < include.length; i++) {
    if (include[i].matches(url)) {
      includeMatch = true;
      break;
    }
  }
  if (!includeMatch) {
    return false;
  }
  for (let i = 0; i < exclude.length; i++) {
    if (exclude[i].matches(url)) {
      return false;
    }
  }
  return true;
}

/**
 * 通用参数过滤算法：遍历所有规则，累积匹配规则的 params（小写），
 * 然后从 URL 中移除这些参数（参数名大小写不敏感）。
 */
export function processQueryRules(url: string, rules: BraveQueryRule[]): string {
  const parsed = parseUrl(url);
  if (parsed === null) {
    return url;
  }

  const paramsToRemove: string[] = [];
  for (let i = 0; i < rules.length; i++) {
    const rule = rules[i];
    if (ruleMatches(parsed, rule.compiledInclude, rule.compiledExclude)) {
      for (let j = 0; j < rule.params.length; j++) {
        const param = rule.params[j].toLowerCase();
        if (paramsToRemove.indexOf(param) < 0) {
          paramsToRemove.push(param);
        }
      }
    }
  }

  if (paramsToRemove.length === 0) {
    return url;
  }

  const newQuery = filterParamsByList(parsed.query, paramsToRemove);
  return rebuildUrlWithQuery(parsed, newQuery);
}

function filterParamsByList(query: string, paramsToRemove: string[]): string {
  if (query.length === 0) {
    return '';
  }
  const pairs = query.split('&');
  const kept: string[] = [];
  for (let i = 0; i < pairs.length; i++) {
    const pair = pairs[i];
    const eqIdx = pair.indexOf('=');
    const key = eqIdx >= 0 ? pair.substring(0, eqIdx) : pair;
    if (paramsToRemove.indexOf(key.toLowerCase()) < 0) {
      kept.push(pair);
    }
  }
  return kept.join('&');
}
