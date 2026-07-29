export function extractUrlList(text: string, validateUrls: boolean = true, truncateNonAscii: boolean = false): string[] {
  let preProcessedText = text;
  if (truncateNonAscii) {
    let result = '';
    for (let i = 0; i < preProcessedText.length; i++) {
      const code = preProcessedText.charCodeAt(i);
      if (code <= 127) {
        result += preProcessedText.charAt(i);
      } else {
        result += ' ';
      }
    }
    preProcessedText = result;
  }

  const bracketChars = ['<', '>', '(', ')', '[', ']', '{', '}'];
  let cleaned = '';
  for (let i = 0; i < preProcessedText.length; i++) {
    const ch = preProcessedText.charAt(i);
    if (bracketChars.indexOf(ch) >= 0) {
      cleaned += ' ';
    } else {
      cleaned += ch;
    }
  }
  preProcessedText = cleaned;

  const URL_PATTERN = '(https?://)?(www\\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\\.[a-zA-Z][a-zA-Z0-9()]{0,5}\\b([-a-zA-Z0-9()@:%_+.~#?&/=]*)';
  const regex = new RegExp(URL_PATTERN, 'g');
  const matches = preProcessedText.match(regex);

  let extractedLinks: string[] = [];
  if (matches !== null) {
    for (let i = 0; i < matches.length; i++) {
      const trimmed = matches[i].trim();
      if (trimmed.length > 0) {
        extractedLinks.push(removeTrailingDotFromHost(trimmed));
      }
    }
  }

  if (validateUrls) {
    const validated: string[] = [];
    for (let i = 0; i < extractedLinks.length; i++) {
      if (isValidUrl(extractedLinks[i])) {
        validated.push(extractedLinks[i]);
      }
    }
    extractedLinks = validated;
  }

  const distinct: string[] = [];
  const seen: Record<string, boolean> = {};
  for (let i = 0; i < extractedLinks.length; i++) {
    if (!seen[extractedLinks[i]]) {
      seen[extractedLinks[i]] = true;
      distinct.push(extractedLinks[i]);
    }
  }
  return distinct;
}

function isValidUrl(url: string): boolean {
  try {
    let formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'http://' + url;
    }
    const parsed = parseUrl(formattedUrl);
    if (parsed === null) {
      return false;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (parsed.host.indexOf('.') < 0) {
        return false;
      }
    }
    const lastDot = parsed.host.lastIndexOf('.');
    if (lastDot >= 0) {
      const tld = parsed.host.substring(lastDot + 1);
      if (tld.length > 0 && isAllDigits(tld)) {
        return false;
      }
    }
    return true;
  } catch (e) {
    return false;
  }
}

function isAllDigits(s: string): boolean {
  for (let i = 0; i < s.length; i++) {
    const code = s.charCodeAt(i);
    if (code < 48 || code > 57) {
      return false;
    }
  }
  return true;
}

function removeTrailingDotFromHost(url: string): string {
  try {
    let formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'http://' + url;
    }
    const parsed = parseUrl(formattedUrl);
    if (parsed === null) {
      return url;
    }
    if (parsed.host.endsWith('.')) {
      const cleanedHost = parsed.host.substring(0, parsed.host.length - 1);
      return url.replace(parsed.host, cleanedHost);
    }
    return url;
  } catch (e) {
    return url;
  }
}

interface ParsedUrl {
  protocol: string;
  host: string;
  port: string;
  path: string;
  query: string;
  fragment: string;
}

function parseUrl(url: string): ParsedUrl | null {
  try {
    let protocol = '';
    let rest = url;
    const protoIdx = url.indexOf('://');
    if (protoIdx >= 0) {
      protocol = url.substring(0, protoIdx);
      rest = url.substring(protoIdx + 3);
    }
    let host = '';
    let path = '/';
    let query = '';
    let fragment = '';
    let port = '';
    const slashIdx = rest.indexOf('/');
    const queryIdx = rest.indexOf('?');
    const fragmentIdx = rest.indexOf('#');
    let hostEnd = rest.length;
    if (slashIdx >= 0 && slashIdx < hostEnd) hostEnd = slashIdx;
    if (queryIdx >= 0 && queryIdx < hostEnd) hostEnd = queryIdx;
    if (fragmentIdx >= 0 && fragmentIdx < hostEnd) hostEnd = fragmentIdx;
    host = rest.substring(0, hostEnd);
    const colonIdx = host.indexOf(':');
    if (colonIdx >= 0) {
      port = host.substring(colonIdx + 1);
      host = host.substring(0, colonIdx);
    }
    const afterHost = rest.substring(hostEnd);
    const hashIdx = afterHost.indexOf('#');
    if (hashIdx >= 0) {
      fragment = afterHost.substring(hashIdx + 1);
      const beforeHash = afterHost.substring(0, hashIdx);
      const qIdx = beforeHash.indexOf('?');
      if (qIdx >= 0) {
        query = beforeHash.substring(qIdx + 1);
        path = beforeHash.substring(0, qIdx);
      } else {
        path = beforeHash;
      }
    } else {
      const qIdx = afterHost.indexOf('?');
      if (qIdx >= 0) {
        query = afterHost.substring(qIdx + 1);
        path = afterHost.substring(0, qIdx);
      } else {
        path = afterHost;
      }
    }
    if (host.length === 0) {
      return null;
    }
    const result: ParsedUrl = {
      protocol: protocol,
      host: host,
      port: port,
      path: path.length > 0 ? path : '/',
      query: query,
      fragment: fragment,
    };
    return result;
  } catch (e) {
    return null;
  }
}

export function buildUrl(parsed: ParsedUrl): string {
  let result = '';
  if (parsed.protocol.length > 0) {
    result += parsed.protocol + '://';
  }
  result += parsed.host;
  if (parsed.port.length > 0) {
    result += ':' + parsed.port;
  }
  result += parsed.path;
  if (parsed.query.length > 0) {
    result += '?' + parsed.query;
  }
  if (parsed.fragment.length > 0) {
    result += '#' + parsed.fragment;
  }
  return result;
}

export function rebuildUrlWithQuery(parsed: ParsedUrl, newQuery: string): string {
  const result: ParsedUrl = {
    protocol: parsed.protocol,
    host: parsed.host,
    port: parsed.port,
    path: parsed.path,
    query: newQuery,
    fragment: parsed.fragment,
  };
  return buildUrl(result);
}

export function filterParams(query: string, targetParams: string[]): string {
  if (query.length === 0) {
    return '';
  }
  const pairs = query.split('&');
  const kept: string[] = [];
  for (let i = 0; i < pairs.length; i++) {
    const pair = pairs[i];
    const eqIdx = pair.indexOf('=');
    const key = eqIdx >= 0 ? pair.substring(0, eqIdx) : pair;
    let found = false;
    for (let j = 0; j < targetParams.length; j++) {
      if (key === targetParams[j]) {
        found = true;
        break;
      }
    }
    if (!found) {
      kept.push(pair);
    }
  }
  return kept.join('&');
}

export function filterParamsByPrefix(query: string, prefix: string): string {
  if (query.length === 0) {
    return '';
  }
  const pairs = query.split('&');
  const kept: string[] = [];
  for (let i = 0; i < pairs.length; i++) {
    const pair = pairs[i];
    const eqIdx = pair.indexOf('=');
    const key = eqIdx >= 0 ? pair.substring(0, eqIdx) : pair;
    if (!key.startsWith(prefix)) {
      kept.push(pair);
    }
  }
  return kept.join('&');
}

export { parseUrl, ParsedUrl };
