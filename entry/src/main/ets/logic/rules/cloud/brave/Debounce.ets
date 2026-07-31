import { buffer } from '@kit.ArkTS';
import { ParsedUrl, parseUrl } from '../../../../utils/LinkExtractor';
import { UrlPattern } from './UrlPattern';
import { compilePatterns, ruleMatches } from './QueryRules';

export class DebounceRuleKeys {
  static readonly RULES: string = 'cloud_brave_debounce_rules';
  static readonly VERSION_HASH: string = 'cloud_brave_debounce_version_hash';
}

export interface DebounceRuleJson {
  include?: string[];
  exclude?: string[];
  action?: string;
  param?: string;
  prepend_scheme?: string;
  redirect_url_template?: string;
}

/**
 * Brave Debounce 重定向规则。
 * 通过 action 字段区分四种重定向方式：
 * - redirect / base64,redirect：从查询参数中提取目标 URL
 * - regex-path / regex-path-template：用正则从路径中提取目标 URL
 */
export class DebounceRule {
  include: string[] = [];
  exclude: string[] = [];
  action: string | null = null;
  param: string | null = null;
  prependScheme: string | null = null;
  redirectUrlTemplate: string | null = null;
  compiledInclude: UrlPattern[] = [];
  compiledExclude: UrlPattern[] = [];

  static fromJson(obj: DebounceRuleJson): DebounceRule {
    const rule = new DebounceRule();
    rule.include = obj.include !== undefined ? obj.include : [];
    rule.exclude = obj.exclude !== undefined ? obj.exclude : [];
    rule.action = obj.action !== undefined ? obj.action : null;
    rule.param = obj.param !== undefined ? obj.param : null;
    rule.prependScheme = obj.prepend_scheme !== undefined ? obj.prepend_scheme : null;
    rule.redirectUrlTemplate = obj.redirect_url_template !== undefined ? obj.redirect_url_template : null;
    rule.compiledInclude = compilePatterns(rule.include);
    rule.compiledExclude = compilePatterns(rule.exclude);
    return rule;
  }
}

export function parseDebounce(body: string): DebounceRule[] {
  const json = JSON.parse(body) as DebounceRuleJson[];
  const rules: DebounceRule[] = [];
  for (let i = 0; i < json.length; i++) {
    rules.push(DebounceRule.fromJson(json[i]));
  }
  return rules;
}

export function decodeDebounceRules(raw: string): DebounceRule[] {
  if (raw.length === 0) {
    return [];
  }
  return parseDebounce(raw);
}

/**
 * 遍历规则，返回第一个匹配且能解析出目标 URL 的重定向结果。
 * 无匹配时返回 null，调用方保持原 URL 不变。
 */
export function processDebounce(url: string, rules: DebounceRule[]): string | null {
  const parsed = parseUrl(url);
  if (parsed === null) {
    return null;
  }

  for (let i = 0; i < rules.length; i++) {
    const rule = rules[i];
    if (!ruleMatches(parsed, rule.compiledInclude, rule.compiledExclude)) {
      continue;
    }
    const target = resolveDebounceTarget(parsed, rule);
    if (target !== null) {
      return target;
    }
  }
  return null;
}

function resolveDebounceTarget(url: ParsedUrl, rule: DebounceRule): string | null {
  const action = rule.action;
  if (action === null) {
    return null;
  }

  try {
    if (action === 'redirect' || action === 'base64,redirect') {
      return resolveRedirect(url, rule, action);
    }
    if (action === 'regex-path' || action === 'regex-path-template') {
      return resolveRegexPath(url, rule, action);
    }
  } catch (e) {
    return null;
  }
  return null;
}

function resolveRedirect(url: ParsedUrl, rule: DebounceRule, action: string): string | null {
  const paramName = rule.param;
  if (paramName === null) {
    return null;
  }
  const raw = getQueryParam(url.query, paramName);
  if (raw === null || raw.length === 0) {
    return null;
  }

  // `redirect` 动作的参数值是 percent-encoded 的 URL，需先解码；
  // `base64,redirect` 则只做 base64 解码，不再二次 URI 解码。
  const decoded = action.startsWith('base64') ? decodeBase64Url(raw) : safeDecodeURIComponent(raw);
  if (decoded === null) {
    return null;
  }
  return buildTargetUrl(decoded);
}

function resolveRegexPath(url: ParsedUrl, rule: DebounceRule, action: string): string | null {
  const pattern = rule.param;
  if (pattern === null) {
    return null;
  }

  const regex = new RegExp(pattern);
  const match = regex.exec(url.path);
  if (match === null) {
    return null;
  }

  const captures: string[] = [];
  for (let i = 1; i < match.length; i++) {
    captures.push(match[i]);
  }
  if (captures.length === 0) {
    return null;
  }

  let raw: string;
  if (action === 'regex-path') {
    const scheme = rule.prependScheme !== null ? rule.prependScheme : 'https';
    raw = scheme + '://' + captures.join('/');
  } else {
    // regex-path-template
    const template = rule.redirectUrlTemplate;
    if (template === null) {
      return null;
    }
    raw = replaceTemplate(template, captures);
  }

  // 透传原 URL 的 query：若目标本身未携带 query，则附加原 query。
  if (url.query.length > 0 && raw.indexOf('?') < 0) {
    raw += '?' + url.query;
  }
  return buildTargetUrl(raw);
}

function buildTargetUrl(raw: string): string | null {
  const withScheme = raw.indexOf('://') >= 0 ? raw : 'https://' + raw;
  const parsed = parseUrl(withScheme);
  return parsed !== null ? withScheme : null;
}

function getQueryParam(query: string, name: string): string | null {
  if (query.length === 0) {
    return null;
  }
  const pairs = query.split('&');
  for (let i = 0; i < pairs.length; i++) {
    const pair = pairs[i];
    const eqIdx = pair.indexOf('=');
    const key = eqIdx >= 0 ? pair.substring(0, eqIdx) : pair;
    if (key === name) {
      return eqIdx >= 0 ? pair.substring(eqIdx + 1) : '';
    }
  }
  return null;
}

function replaceTemplate(template: string, captures: string[]): string {
  let result = template;
  for (let i = 0; i < captures.length; i++) {
    const placeholder = '$' + (i + 1);
    result = result.replaceAll(placeholder, captures[i]);
  }
  return result;
}

function decodeBase64Url(raw: string): string | null {
  const trimmed = raw.trim();
  if (trimmed.length === 0) {
    return null;
  }
  try {
    let normalized = trimmed.replaceAll('-', '+').replaceAll('_', '/');
    const paddingNeeded = (4 - normalized.length % 4) % 4;
    for (let i = 0; i < paddingNeeded; i++) {
      normalized += '=';
    }
    return buffer.from(normalized, 'base64').toString('utf-8');
  } catch (e) {
    return null;
  }
}

function safeDecodeURIComponent(raw: string): string | null {
  try {
    return decodeURIComponent(raw);
  } catch (e) {
    return null;
  }
}
