import { ParsedUrl } from '../../../../utils/LinkExtractor';

const REGEX_SPECIAL_CHARS: string = '.*+?^${}()|[]\\';

/**
 * URL 模式匹配引擎，支持 Brave 规则的 `*://*.example.com/*` 格式。
 *
 * - scheme: `*` 表示任意，否则按名匹配（大小写不敏感）
 * - host: `*`（任意）、`*.example.com`（域名后缀匹配）、精确匹配（大小写不敏感）
 * - path: glob 模式，`*` 转为 `.*`，其它字符转义，整体锚定 `^...$`
 */
export class UrlPattern {
  private readonly schemePattern: string;
  private readonly hostPattern: string;
  private readonly pathRegex: RegExp | null;
  private readonly neverMatches: boolean;

  private constructor(scheme: string, host: string, pathRegex: RegExp | null, neverMatches: boolean) {
    this.schemePattern = scheme;
    this.hostPattern = host;
    this.pathRegex = pathRegex;
    this.neverMatches = neverMatches;
  }

  matches(url: ParsedUrl): boolean {
    if (this.neverMatches) {
      return false;
    }

    // scheme 匹配
    if (this.schemePattern !== '*' &&
      url.protocol.toLowerCase() !== this.schemePattern.toLowerCase()) {
      return false;
    }

    // host 匹配
    const host = url.host.toLowerCase();
    if (this.hostPattern === '*') {
      // 任意 host
    } else if (this.hostPattern.startsWith('*.')) {
      // `*.example.com` 既匹配 `www.example.com` 也匹配裸域名 `example.com`
      const suffix = this.hostPattern.substring(2);
      if (host !== suffix && !host.endsWith('.' + suffix)) {
        return false;
      }
    } else {
      if (host !== this.hostPattern) {
        return false;
      }
    }

    // path+query 匹配（空 path 归一化为 "/" 以保持 HTTP 语义）
    if (this.pathRegex !== null) {
      const effectivePath = url.path.length > 0 ? url.path : '/';
      const pathWithQuery = url.query.length > 0
        ? effectivePath + '?' + url.query
        : effectivePath;
      if (!this.pathRegex.test(pathWithQuery)) {
        return false;
      }
    }

    return true;
  }

  static compile(pattern: string): UrlPattern {
    const schemeSeparator = pattern.indexOf('://');
    if (schemeSeparator < 0) {
      return new UrlPattern('', '', null, true);
    }

    const scheme = pattern.substring(0, schemeSeparator);
    const rest = pattern.substring(schemeSeparator + 3);
    const slashIndex = rest.indexOf('/');
    const host = slashIndex < 0 ? rest : rest.substring(0, slashIndex);
    const pathPattern = slashIndex < 0 ? '' : rest.substring(slashIndex);

    return new UrlPattern(
      scheme,
      host.toLowerCase(),
      pathPattern.length === 0 ? null : globToRegex(pathPattern),
      false,
    );
  }
}

function globToRegex(pattern: string): RegExp {
  let regex = '^';
  for (let i = 0; i < pattern.length; i++) {
    const c = pattern.charAt(i);
    if (c === '*') {
      regex += '.*';
    } else {
      regex += escapeRegexChar(c);
    }
  }
  regex += '$';
  return new RegExp(regex);
}

function escapeRegexChar(c: string): string {
  return REGEX_SPECIAL_CHARS.indexOf(c) >= 0 ? '\\' + c : c;
}
