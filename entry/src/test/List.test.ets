import localUnitTest from './LocalUnit.test';
import linkExtractorTest from './LinkExtractor.test';
import utmParamsTest from './UTMParams.test';
import queryStrippingTest from './QueryStripping.test';

export default function testsuite() {
  localUnitTest();
  linkExtractorTest();
  utmParamsTest();
  queryStrippingTest();
}