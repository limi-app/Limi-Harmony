import { describe, expect, it } from '@ohos/hypium';
import {
  ClearUrlsProvider,
  ClearUrlsCatalog,
  processClearUrls,
  parseClearUrls,
  decodeClearUrlsRules,
} from '../main/ets/logic/rules/cloud/clearurls/ClearUrls';

function makeProvider(
  urlPattern: string,
  rules: string[] = [],
  rawRules: string[] = [],
  referralMarketing: string[] = [],
  exceptions: string[] = [],
  redirections: string[] = [],
  completeProvider: boolean = false,
): ClearUrlsProvider {
  return ClearUrlsProvider.fromJson({
    urlPattern: urlPattern,
    rules: rules,
    rawRules: rawRules,
    referralMarketing: referralMarketing,
    exceptions: exceptions,
    redirections: redirections,
    completeProvider: completeProvider,
  });
}

function makeCatalog(name: string, provider: ClearUrlsProvider): ClearUrlsCatalog {
  const catalog = new ClearUrlsCatalog();
  catalog.providers.set(name, provider);
  return catalog;
}

function makeCatalog2(
  name1: string, provider1: ClearUrlsProvider,
  name2: string, provider2: ClearUrlsProvider,
): ClearUrlsCatalog {
  const catalog = new ClearUrlsCatalog();
  catalog.providers.set(name1, provider1);
  catalog.providers.set(name2, provider2);
  return catalog;
}

export default function clearUrlsTest() {
  describe('ClearUrlsTest', () => {

    // ── 全局参数清洗 ──────────────────────────────────────────────────

    it('removeGlobalTrackingParams', 0, () => {
      const catalog = makeCatalog('globalRules', makeProvider(
        '.*',
        ['(?:%3F)?utm(?:_[a-z_]*)?', 'gclid', 'yclid'],
      ));
      const result = processClearUrls(
        'https://example.com/page?utm_source=news&gclid=1&yclid=2&keep=1',
        catalog,
      );
      expect(result).assertEqual('https://example.com/page?keep=1');
    });

    it('paramRemovalIsCaseInsensitive', 0, () => {
      const catalog = makeCatalog('globalRules', makeProvider(
        '.*',
        ['(?:%3F)?utm(?:_[a-z_]*)?', 'gclid', 'yclid'],
      ));
      const result = processClearUrls(
        'https://example.com/page?UTM_SOURCE=x&Gclid=y&keep=1',
        catalog,
      );
      expect(result).assertEqual('https://example.com/page?keep=1');
    });

    // ── 站点正则匹配 ──────────────────────────────────────────────────

    it('removeSiteSpecificRegexParams', 0, () => {
      const catalog = makeCatalog('amazon', makeProvider(
        '^https?:\\/\\/(?:[a-z0-9-]+\\.)*?amazon(?:\\.com)?',
        ['ref', 'tag', 'p[fd]_rd_[a-z]*'],
      ));
      const result = processClearUrls(
        'https://www.amazon.com/dp/1?ref=a&tag=b&pf_rd_p=1&pf_rd_r=2&keep=1',
        catalog,
      );
      expect(result).assertEqual('https://www.amazon.com/dp/1?keep=1');
    });

    it('nonMatchingHostUntouched', 0, () => {
      const catalog = makeCatalog('amazon', makeProvider(
        '^https?:\\/\\/(?:[a-z0-9-]+\\.)*?amazon(?:\\.com)?',
        ['ref'],
      ));
      const result = processClearUrls('https://example.com/?ref=1', catalog);
      expect(result).assertEqual('https://example.com/?ref=1');
    });

    // ── exceptions ────────────────────────────────────────────────────

    it('exceptionSkipsProvider', 0, () => {
      const catalog = makeCatalog('example', makeProvider(
        '.*',
        ['foo'],
        [],
        [],
        ['^https?://example\\.com/no'],
      ));
      const excluded = processClearUrls('https://example.com/no?foo=1', catalog);
      expect(excluded).assertEqual('https://example.com/no?foo=1');
      const included = processClearUrls('https://example.com/yes?foo=1', catalog);
      expect(included).assertEqual('https://example.com/yes');
    });

    // ── rawRules ──────────────────────────────────────────────────────

    it('applyRawRules', 0, () => {
      const catalog = makeCatalog('test', makeProvider(
        '.*',
        [],
        ['/ref=[^/|?]*'],
      ));
      const result = processClearUrls(
        'https://example.com/path/ref=abc?keep=1',
        catalog,
      );
      expect(result).assertEqual('https://example.com/path?keep=1');
    });

    // ── 重定向 ────────────────────────────────────────────────────────

    it('resolveSimpleRedirection', 0, () => {
      const catalog = makeCatalog('redirect', makeProvider(
        '.*',
        [],
        [],
        [],
        [],
        ['^https?://redirect\\.com\\/go\\?url=([^&]+)'],
      ));
      const result = processClearUrls(
        'https://redirect.com/go?url=https%3A%2F%2Fexample.com%2Fpath',
        catalog,
      );
      expect(result).assertEqual('https://example.com/path');
    });

    it('redirectionWithoutSchemeGetsHttpPrefix', 0, () => {
      const catalog = makeCatalog('r', makeProvider(
        '.*',
        [],
        [],
        [],
        [],
        ['^https?://r\\.com\\?to=(.*)'],
      ));
      const result = processClearUrls('https://r.com?to=example.com', catalog);
      expect(result).assertEqual('http://example.com');
    });

    // ── 多级百分号编码重定向 ──────────────────────────────────────────

    it('doubleEncodedRedirectionDecodedRecursively', 0, () => {
      const catalog = makeCatalog('r', makeProvider(
        '.*',
        [],
        [],
        [],
        [],
        ['^https?://r\\.com\\?to=(.*)'],
      ));
      const result = processClearUrls(
        'https://r.com?to=https%253A%252F%252Fexample.com',
        catalog,
      );
      expect(result).assertEqual('https://example.com');
    });

    it('multiLayerEncodedHostGetsHttpPrefix', 0, () => {
      const catalog = makeCatalog('r', makeProvider(
        '.*',
        [],
        [],
        [],
        [],
        ['^https?://r\\.com\\?to=(.*)'],
      ));
      const result = processClearUrls(
        'https://r.com?to=e%2578ample.com',
        catalog,
      );
      expect(result).assertEqual('http://example.com');
    });

    // ── 大小写不敏感 scheme 保留 ──────────────────────────────────────

    it('redirectionPreservesUppercaseScheme', 0, () => {
      const catalog = makeCatalog('r', makeProvider(
        '.*',
        [],
        [],
        [],
        [],
        ['^https?://r\\.com\\?to=(.*)'],
      ));
      const result = processClearUrls(
        'https://r.com?to=HTTPS%3A%2F%2FExample.com',
        catalog,
      );
      expect(result).assertEqual('HTTPS://Example.com');
    });

    // ── mailto 与协议相对 URL ─────────────────────────────────────────

    it('redirectionPreservesMailtoScheme', 0, () => {
      const catalog = makeCatalog('r', makeProvider(
        '.*',
        [],
        [],
        [],
        [],
        ['^https?://r\\.com\\?to=(.*)'],
      ));
      const result = processClearUrls(
        'https://r.com?to=mailto%3Auser%40example.com',
        catalog,
      );
      expect(result).assertEqual('mailto:user@example.com');
    });

    it('schemeRelativeRedirectionDefaultsToHttps', 0, () => {
      const catalog = makeCatalog('r', makeProvider(
        '.*',
        [],
        [],
        [],
        [],
        ['^https?://r\\.com\\?to=(.*)'],
      ));
      const result = processClearUrls(
        'https://r.com?to=%2F%2Fexample.com%2Fpath',
        catalog,
      );
      expect(result).assertEqual('https://example.com/path');
    });

    // ── 重定向后递归清洗 ──────────────────────────────────────────────

    it('recursiveCleaningAfterRedirection', 0, () => {
      const catalog = makeCatalog2(
        'go', makeProvider(
          '^https?://go\\.com',
          [],
          [],
          [],
          [],
          ['^https?://go\\.com\\?url=([^&]+)'],
        ),
        'global', makeProvider(
          '.*',
          ['utm_(?:source|medium|campaign)'],
        ),
      );
      const result = processClearUrls(
        'https://go.com?url=https%3A%2F%2Fexample.com%3Futm_source%3Dx%26keep%3D1',
        catalog,
      );
      expect(result).assertEqual('https://example.com?keep=1');
    });

    // ── fragment 参数清洗 ─────────────────────────────────────────────

    it('removeFragmentParams', 0, () => {
      const catalog = makeCatalog('g', makeProvider(
        '.*',
        ['ref'],
      ));
      const result = processClearUrls(
        'https://example.com/page#ref=1&keep=2',
        catalog,
      );
      expect(result).assertEqual('https://example.com/page#keep=2');
    });

    // ── completeProvider 跳过 ─────────────────────────────────────────

    it('completeProviderSkipped', 0, () => {
      const catalog = makeCatalog('blocked', makeProvider(
        '.*',
        ['ref'],
        [],
        [],
        [],
        [],
        true,
      ));
      const result = processClearUrls('https://example.com/?ref=1', catalog);
      expect(result).assertEqual('https://example.com/?ref=1');
    });

    // ── 非法正则容错 ──────────────────────────────────────────────────

    it('invalidRegexIsTolerated', 0, () => {
      const catalog = makeCatalog('bad', makeProvider(
        '.*',
        ['[invalid', 'ref'],
      ));
      const result = processClearUrls(
        'https://example.com/?ref=1&keep=2',
        catalog,
      );
      expect(result).assertEqual('https://example.com/?keep=2');
    });

    // ── referralMarketing ─────────────────────────────────────────────

    it('referralMarketingParamsRemoved', 0, () => {
      const catalog = makeCatalog('globalRules', makeProvider(
        '.*',
        [],
        [],
        ['(?:%3F)?ref_?'],
      ));
      const result = processClearUrls(
        'https://example.com/?ref=abc&keep=1',
        catalog,
      );
      expect(result).assertEqual('https://example.com/?keep=1');
    });

    // ── 真实 JSON 解析 + 多 provider 综合 ─────────────────────────────

    it('parseRealCatalogShapeAndProcess', 0, () => {
      const amazonPattern: string = JSON.stringify(
        '^https?:\\/\\/(?:[a-z0-9-]+\\.)*?amazon(?:\\.com)?',
      );
      const blockedPattern: string = JSON.stringify(
        '^https?:\\/\\/ads\\.example\\.com',
      );
      const json: string = ''
        + '{"providers":{'
        + '"globalRules":{"urlPattern":".*","rules":["(?:%3F)?utm(?:_[a-z_]*)?","(?:%3F)?yclid"],"referralMarketing":["(?:%3F)?ref_?","(?:%3F)?referrer"],"exceptions":[]},'
        + '"amazon":{"urlPattern":' + amazonPattern + ',"completeProvider":false,"rules":["ref","tag"],"rawRules":["/ref=[^/|?]*"],"referralMarketing":[],"exceptions":[],"redirections":[]},'
        + '"blocked":{"urlPattern":' + blockedPattern + ',"completeProvider":true}'
        + '}}';
      const catalog = parseClearUrls(json);
      expect(catalog.providers.size).assertEqual(3);
      const result = processClearUrls(
        'https://www.amazon.com/dp/1?ref=a&tag=b&utm_source=x&keep=1',
        catalog,
      );
      expect(result).assertEqual('https://www.amazon.com/dp/1?keep=1');
    });

    // ── 空目录不修改 URL ──────────────────────────────────────────────

    it('emptyCatalogReturnsOriginal', 0, () => {
      const catalog = new ClearUrlsCatalog();
      const result = processClearUrls('https://example.com/?ref=1', catalog);
      expect(result).assertEqual('https://example.com/?ref=1');
    });

    // ── 损坏 JSON 容错 ────────────────────────────────────────────────

    it('malformedJsonReturnsEmptyCatalog', 0, () => {
      const catalog = decodeClearUrlsRules('{ broken json');
      expect(catalog.providers.size).assertEqual(0);
      const result = processClearUrls('https://example.com/?ref=1', catalog);
      expect(result).assertEqual('https://example.com/?ref=1');
    });
  });
}
