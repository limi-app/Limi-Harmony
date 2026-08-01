/**
 * ClearURLs.xyz 规则实现。
 *
 * 数据来源：https://rules1.clearurls.xyz/data.minify.json
 * 版本校验：https://rules1.clearurls.xyz/rules.minify.hash (SHA-256)
 *
 * 清洗语义对照 ClearURLs 官方 Addon 源码：
 * - 站点匹配 = urlPattern 正则（忽略大小写）命中完整 URL 且所有 exceptions 都不命中
 * - rules + referralMarketing 合并为针对参数名的大小写不敏感、^rule$ 锚定正则，同时清洗 query 与 fragment 参数
 * - rawRules 对整条 URL 做 replace(regex, "", "gi")
 * - redirections 取首个命中正则的捕获组 1，反复百分号解码直至稳定后 trim，
 *   // 开头补 https:，含合法 scheme 则原样保留，否则补 http://
 * - 外层循环反复清洗直至 URL 稳定（上限 20 次）
 * - completeProvider: true 的 provider 在分享场景无意义，跳过
 */

const MAX_CLEANING_ITERATIONS: number = 20;
const SCHEME_REGEX: RegExp = /^[a-zA-Z][a-zA-Z0-9+.-]*:/;

// ── 存储键 ─────────────────────────────────────────────────────────────

export class ClearUrlsRuleKeys {
  static readonly RULES: string = 'cloud_clearurls_rules';
  static readonly VERSION_HASH: string = 'cloud_clearurls_version_hash';
}

// ── JSON 接口 ──────────────────────────────────────────────────────────

export interface ClearUrlsProviderJson {
  urlPattern?: string;
  completeProvider?: boolean;
  rules?: string[];
  rawRules?: string[];
  referralMarketing?: string[];
  exceptions?: string[];
  redirections?: string[];
}

export interface ClearUrlsCatalogJson {
  providers?: Record<string, ClearUrlsProviderJson>;
}

// ── 数据模型 ────────────────────────────────────────────────────────────

export class ClearUrlsProvider {
  urlPattern: string = '';
  completeProvider: boolean = false;
  rules: string[] = [];
  rawRules: string[] = [];
  referralMarketing: string[] = [];
  exceptions: string[] = [];
  redirections: string[] = [];

  compiledUrlPattern: RegExp | null = null;
  compiledRules: RegExp[] = [];
  compiledRawRules: RegExp[] = [];
  compiledExceptions: RegExp[] = [];
  compiledRedirections: RegExp[] = [];

  static fromJson(obj: ClearUrlsProviderJson): ClearUrlsProvider {
    const p = new ClearUrlsProvider();
    p.urlPattern = obj.urlPattern !== undefined ? obj.urlPattern : '';
    p.completeProvider = obj.completeProvider !== undefined ? obj.completeProvider : false;
    p.rules = obj.rules !== undefined ? obj.rules : [];
    p.rawRules = obj.rawRules !== undefined ? obj.rawRules : [];
    p.referralMarketing = obj.referralMarketing !== undefined ? obj.referralMarketing : [];
    p.exceptions = obj.exceptions !== undefined ? obj.exceptions : [];
    p.redirections = obj.redirections !== undefined ? obj.redirections : [];

    p.compiledUrlPattern = compileRegex(p.urlPattern, 'i');
    // rules + referralMarketing 合并，全匹配锚定
    const combined = p.rules.concat(p.referralMarketing);
    p.compiledRules = compileAll(combined, true);
    p.compiledRawRules = compileAll(p.rawRules, false, 'gi');
    p.compiledExceptions = compileAll(p.exceptions, false, 'i');
    p.compiledRedirections = compileAll(p.redirections, false, 'i');
    return p;
  }
}

export class ClearUrlsCatalog {
  providers: Map<string, ClearUrlsProvider> = new Map<string, ClearUrlsProvider>();

  static fromJson(json: ClearUrlsCatalogJson): ClearUrlsCatalog {
    const catalog = new ClearUrlsCatalog();
    const providersObj = json.providers;
    if (providersObj !== undefined && providersObj !== null) {
      const names = Object.keys(providersObj);
      for (let i = 0; i < names.length; i++) {
        const name = names[i];
        const p = providersObj[name];
        if (p !== undefined && p !== null) {
          catalog.providers.set(name, ClearUrlsProvider.fromJson(p));
        }
      }
    }
    return catalog;
  }
}

// ── 解析入口 ────────────────────────────────────────────────────────────

export function parseClearUrls(body: string): ClearUrlsCatalog {
  return ClearUrlsCatalog.fromJson(JSON.parse(body) as ClearUrlsCatalogJson);
}

export function decodeClearUrlsRules(raw: string): ClearUrlsCatalog {
  if (raw.length === 0) {
    return new ClearUrlsCatalog();
  }
  try {
    return parseClearUrls(raw);
  } catch (e) {
    return new ClearUrlsCatalog();
  }
}

// ── 清洗主入口 ──────────────────────────────────────────────────────────

export function processClearUrls(url: string, catalog: ClearUrlsCatalog): string {
  const providers: ClearUrlsProvider[] = [];
  catalog.providers.forEach((provider: ClearUrlsProvider) => {
    if (!provider.completeProvider) {
      providers.push(provider);
    }
  });
  if (providers.length === 0) {
    return url;
  }

  let current = url;
  let iterations = 0;
  while (iterations < MAX_CLEANING_ITERATIONS) {
    const cleaned = cleanOnce(current, providers);
    if (cleaned === current) {
      break;
    }
    current = cleaned;
    iterations++;
  }
  if (current.length === 0) {
    return url;
  }
  return current;
}

// ── 单趟清洗 ────────────────────────────────────────────────────────────

function cleanOnce(urlString: string, providers: ClearUrlsProvider[]): string {
  let current = urlString;
  for (let i = 0; i < providers.length; i++) {
    const provider = providers[i];
    if (!providerMatches(provider, current)) {
      continue;
    }
    const redirectTarget = resolveRedirection(provider, current);
    if (redirectTarget !== null) {
      return redirectTarget;
    }
    current = applyRawRules(current, provider.compiledRawRules);
    current = removeFields(current, provider.compiledRules);
  }
  return current;
}

function providerMatches(provider: ClearUrlsProvider, urlString: string): boolean {
  if (provider.compiledUrlPattern === null) {
    return false;
  }
  if (!provider.compiledUrlPattern.test(urlString)) {
    return false;
  }
  for (let i = 0; i < provider.compiledExceptions.length; i++) {
    if (provider.compiledExceptions[i].test(urlString)) {
      return false;
    }
  }
  return true;
}

function resolveRedirection(provider: ClearUrlsProvider, urlString: string): string | null {
  for (let i = 0; i < provider.compiledRedirections.length; i++) {
    const regex = provider.compiledRedirections[i];
    const match = regex.exec(urlString);
    if (match !== null && match.length > 1 && match[1] !== undefined && match[1].length > 0) {
      return decodeRedirectUrl(match[1]);
    }
  }
  return null;
}

function applyRawRules(urlString: string, rawRules: RegExp[]): string {
  let result = urlString;
  for (let i = 0; i < rawRules.length; i++) {
    try {
      result = result.replace(rawRules[i], '');
    } catch (e) {
      // 无效正则容错：跳过
    }
  }
  return result;
}

function removeFields(urlString: string, rules: RegExp[]): string {
  if (rules.length === 0) {
    return urlString;
  }

  let base = urlString;
  let query = '';
  let fragment = '';

  const hashIdx = base.indexOf('#');
  if (hashIdx >= 0) {
    fragment = base.substring(hashIdx + 1);
    base = base.substring(0, hashIdx);
  }
  const qIdx = base.indexOf('?');
  if (qIdx >= 0) {
    query = base.substring(qIdx + 1);
    base = base.substring(0, qIdx);
  }

  let queryChanged = false;
  let fragmentChanged = false;

  if (query.length > 0) {
    const pairs = query.split('&');
    const kept: string[] = [];
    for (let i = 0; i < pairs.length; i++) {
      const pair = pairs[i];
      const eqIdx = pair.indexOf('=');
      const key = eqIdx >= 0 ? pair.substring(0, eqIdx) : pair;
      if (matchesAnyRule(key, rules)) {
        queryChanged = true;
      } else {
        kept.push(pair);
      }
    }
    query = kept.join('&');
  }

  if (fragment.length > 0) {
    const pairs = fragment.split('&');
    const kept: string[] = [];
    for (let i = 0; i < pairs.length; i++) {
      const pair = pairs[i];
      const eqIdx = pair.indexOf('=');
      const key = eqIdx >= 0 ? pair.substring(0, eqIdx) : pair;
      if (matchesAnyRule(key, rules)) {
        fragmentChanged = true;
      } else {
        kept.push(pair);
      }
    }
    fragment = kept.join('&');
  }

  if (!queryChanged && !fragmentChanged) {
    return urlString;
  }

  let result = base;
  if (query.length > 0) {
    result += '?' + query;
  }
  if (fragment.length > 0) {
    result += '#' + fragment;
  }
  return result;
}

function matchesAnyRule(key: string, rules: RegExp[]): boolean {
  for (let i = 0; i < rules.length; i++) {
    if (rules[i].test(key)) {
      return true;
    }
  }
  return false;
}

// ── 重定向目标解码 ───────────────────────────────────────────────────────

function decodeRedirectUrl(raw: string): string {
  let result = percentDecode(raw);
  while (true) {
    const decoded = percentDecode(result);
    if (decoded === result) {
      break;
    }
    result = decoded;
  }
  result = result.trim();

  if (result.startsWith('//')) {
    return 'https:' + result;
  }

  const schemeMatch = SCHEME_REGEX.exec(result);
  const scheme = schemeMatch !== null ? schemeMatch[0].substring(0, schemeMatch[0].length - 1) : null;
  if (scheme !== null && scheme.indexOf('.') < 0) {
    return result;
  }
  return 'http://' + result;
}

function percentDecode(input: string): string {
  try {
    return decodeURIComponent(input);
  } catch (e) {
    return input;
  }
}

// ── 正则编译（容错）─────────────────────────────────────────────────────

function compileRegex(pattern: string, flags: string): RegExp | null {
  if (pattern.length === 0) {
    return null;
  }
  try {
    return new RegExp(pattern, flags);
  } catch (e) {
    return null;
  }
}

function compileFullMatchRegex(pattern: string): RegExp | null {
  if (pattern.length === 0) {
    return null;
  }
  try {
    return new RegExp('^(?:' + pattern + ')$', 'i');
  } catch (e) {
    return null;
  }
}

/**
 * 批量编译正则。
 * @param patterns 正则模式数组
 * @param fullMatch 是否为全匹配模式（用 ^...$ 锚定，用于参数名匹配）
 * @param flags 正则标志（仅 partialMatch 模式下生效）
 */
function compileAll(patterns: string[], fullMatch: boolean, flags: string = 'i'): RegExp[] {
  const result: RegExp[] = [];
  for (let i = 0; i < patterns.length; i++) {
    const r = fullMatch ? compileFullMatchRegex(patterns[i]) : compileRegex(patterns[i], flags);
    if (r !== null) {
      result.push(r);
    }
  }
  return result;
}
