import { describe, expect, it } from '@ohos/hypium';
import { extractUrlList } from '../main/ets/utils/LinkExtractor';

export default function linkExtractorTest() {
  describe('LinkExtractorTest', () => {
    it('testExtractSimpleUrls', 0, () => {
      const text = 'Visit https://www.google.com for more information';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals(['https://www.google.com']);
    });

    it('testExtractMultipleUrls', 0, () => {
      const text = 'Check out https://www.google.com and http://example.com for details';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals(['https://www.google.com', 'http://example.com']);
    });

    it('testExtractUrlsWithPaths', 0, () => {
      const text = 'Documentation at https://developer.android.com/guide/topics/ui can be helpful';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals(['https://developer.android.com/guide/topics/ui']);
    });

    it('testExtractUrlsWithParameters', 0, () => {
      const text = 'Access your account at https://example.com/login?user=test&pass=secret';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals(['https://example.com/login?user=test&pass=secret']);
    });

    it('testExtractUrlsWithoutProtocol', 0, () => {
      const text = 'Visit www.example.com for more info';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals(['www.example.com']);
    });

    it('testExtractUrlsInBrackets', 0, () => {
      const text = 'Link (https://www.example.com) is here';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals(['https://www.example.com']);
    });

    it('testExtractUrlsWithTrailingPunctuation', 0, () => {
      const text = 'Go to https://www.example.com.';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals(['https://www.example.com']);
    });

    it('testExtractDuplicateUrls', 0, () => {
      const text = 'Visit https://www.example.com and https://www.example.com again';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals(['https://www.example.com']);
    });

    it('testExtractNoUrls', 0, () => {
      const text = 'This is just plain text without any URLs';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals([]);
    });

    it('testExtractEmptyText', 0, () => {
      const text = '';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals([]);
    });

    it('testExtractUrlsWithTruncateNonAsciiDisabled', 0, () => {
      const text = 'Visit https://www.example.com and https://www.例子.com';
      const result = extractUrlList(text, true, false);
      expect(result).assertDeepEquals(['https://www.example.com']);
    });

    it('testExtractUrlsWithNumericTld', 0, () => {
      const text = 'No.2: Visit https://www.example.com for more information';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals(['https://www.example.com']);
    });

    it('testExtractUrlsWithNumericTld2', 0, () => {
      const text = 'No.1 No.2 No.3';
      const result = extractUrlList(text);
      expect(result).assertDeepEquals([]);
    });
  });
}
