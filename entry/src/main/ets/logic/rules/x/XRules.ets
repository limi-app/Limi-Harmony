import { parseUrl, buildUrl, ParsedUrl } from '../../../utils/LinkExtractor';

const X_NO_PARAMS_TARGET_HOST: string[] = ['www.x.com', 'x.com', 'www.twitter.com', 'twitter.com'];

export function getXNoParamsTargetHost(): string[] {
  return X_NO_PARAMS_TARGET_HOST;
}

export function processXNoParamsUrl(url: string): string {
  const parsed: ParsedUrl | null = parseUrl(url);
  if (parsed === null) {
    return url;
  }
  const result: ParsedUrl = {
    protocol: parsed.protocol,
    host: parsed.host,
    port: parsed.port,
    path: parsed.path,
    query: '',
    fragment: parsed.fragment,
  };
  return buildUrl(result);
}
