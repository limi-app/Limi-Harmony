import localUnitTest from './LocalUnit.test';
import linkExtractorTest from './LinkExtractor.test';
import utmParamsTest from './UTMParams.test';
import queryStrippingTest from './QueryStripping.test';
import urlPatternTest from './UrlPattern.test';
import cleanUrlsTest from './CleanUrls.test';
import queryFilterTest from './QueryFilter.test';
import debounceTest from './Debounce.test';
import contentHashTest from './ContentHash.test';
import clearUrlsTest from './ClearUrls.test';
import schemeStyleTest from './SchemeStyle.test';

export default function testsuite() {
  localUnitTest();
  linkExtractorTest();
  utmParamsTest();
  queryStrippingTest();
  urlPatternTest();
  cleanUrlsTest();
  queryFilterTest();
  debounceTest();
  contentHashTest();
  clearUrlsTest();
  schemeStyleTest();
}
