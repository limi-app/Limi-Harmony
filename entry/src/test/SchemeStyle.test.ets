import { describe, expect, it } from '@ohos/hypium';
import {
  hasUrlScheme,
  ensureUrlScheme,
  applyOriginalSchemeStyle,
} from '../main/ets/logic/Rule';
import { processUTMParams } from '../main/ets/logic/rules/common/UTMParams';

export default function schemeStyleTest() {
  describe('SchemeStyleTest', () => {

    // ── hasUrlScheme ──────────────────────────────────────────────────

    it('hasSchemeHttp', 0, () => {
      expect(hasUrlScheme('http://example.com')).assertTrue();
    });

    it('hasSchemeHttps', 0, () => {
      expect(hasUrlScheme('https://example.com')).assertTrue();
    });

    it('hasSchemeMailto', 0, () => {
      expect(hasUrlScheme('mailto:user@example.com')).assertTrue();
    });

    it('hasSchemeFtp', 0, () => {
      expect(hasUrlScheme('ftp://ftp.example.com')).assertTrue();
    });

    it('noSchemeBareDomain', 0, () => {
      expect(hasUrlScheme('a.com')).assertFalse();
    });

    it('noSchemeWithPath', 0, () => {
      expect(hasUrlScheme('b23.tv/DxrYn0F')).assertFalse();
    });

    it('noSchemeEmail', 0, () => {
      expect(hasUrlScheme('e@a.com')).assertFalse();
    });

    it('noSchemeWithQuery', 0, () => {
      expect(hasUrlScheme('a.com?utm_source=x')).assertFalse();
    });

    // ── ensureUrlScheme ───────────────────────────────────────────────

    it('ensureSchemeAddsHttp', 0, () => {
      expect(ensureUrlScheme('a.com')).assertEqual('http://a.com');
    });

    it('ensureSchemeKeepsHttp', 0, () => {
      expect(ensureUrlScheme('http://a.com')).assertEqual('http://a.com');
    });

    it('ensureSchemeKeepsHttps', 0, () => {
      expect(ensureUrlScheme('https://a.com')).assertEqual('https://a.com');
    });

    it('ensureSchemeKeepsMailto', 0, () => {
      expect(ensureUrlScheme('mailto:user@example.com')).assertEqual('mailto:user@example.com');
    });

    it('ensureSchemeAddsHttpToB23tv', 0, () => {
      expect(ensureUrlScheme('b23.tv/DxrYn0F')).assertEqual('http://b23.tv/DxrYn0F');
    });

    // ── applyOriginalSchemeStyle ──────────────────────────────────────

    it('stripHttpWhenNoOriginalScheme', 0, () => {
      expect(applyOriginalSchemeStyle('http://a.com', false)).assertEqual('a.com');
    });

    it('keepHttpsWhenNoOriginalScheme', 0, () => {
      expect(applyOriginalSchemeStyle('https://www.bilibili.com/video/BV1', false))
        .assertEqual('https://www.bilibili.com/video/BV1');
    });

    it('keepHttpWhenOriginalHadScheme', 0, () => {
      expect(applyOriginalSchemeStyle('http://a.com', true)).assertEqual('http://a.com');
    });

    it('keepHttpsWhenOriginalHadScheme', 0, () => {
      expect(applyOriginalSchemeStyle('https://a.com', true)).assertEqual('https://a.com');
    });

    // ── 集成：UTM 处理 + scheme 原样式 ────────────────────────────────

    it('protocolLessUrlWithUtmProcessedNoSchemeAdded', 0, () => {
      // 模拟 processUrl 的 scheme 补全/还原逻辑 + UTM 处理
      const input = 'a.com?utm_source=x&keep=1';
      const hadScheme = hasUrlScheme(input);
      const ensured = ensureUrlScheme(input);
      const processed = processUTMParams(ensured);
      const result = applyOriginalSchemeStyle(processed, hadScheme);
      expect(result).assertEqual('a.com?keep=1');
    });

    it('protocolLessUrlNoParamsStaysUnchanged', 0, () => {
      const input = 'e@a.com';
      const hadScheme = hasUrlScheme(input);
      const ensured = ensureUrlScheme(input);
      const processed = processUTMParams(ensured);
      const result = applyOriginalSchemeStyle(processed, hadScheme);
      expect(result).assertEqual('e@a.com');
    });

    it('urlWithSchemeProcessedAndKept', 0, () => {
      const input = 'https://example.com?utm_source=x&keep=1';
      const hadScheme = hasUrlScheme(input);
      const ensured = ensureUrlScheme(input);
      const processed = processUTMParams(ensured);
      const result = applyOriginalSchemeStyle(processed, hadScheme);
      expect(result).assertEqual('https://example.com?keep=1');
    });

    it('b23tvGetsHttpSchemeForRedirect', 0, () => {
      // b23.tv/DxrYn0F 需要 http:// 前缀才能发起 HTTP 重定向请求
      const input = 'b23.tv/DxrYn0F';
      const hadScheme = hasUrlScheme(input);
      const ensured = ensureUrlScheme(input);
      expect(ensured).assertEqual('http://b23.tv/DxrYn0F');
      expect(hadScheme).assertFalse();
      // 重定向目标会是 https://www.bilibili.com/...，不会被去掉协议头
      const redirectTarget = 'https://www.bilibili.com/video/BV1xxx';
      const result = applyOriginalSchemeStyle(redirectTarget, hadScheme);
      expect(result).assertEqual('https://www.bilibili.com/video/BV1xxx');
    });
  });
}
