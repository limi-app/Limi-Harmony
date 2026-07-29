import localUnitTest from './LocalUnit.test';
import linkExtractorTest from './LinkExtractor.test';
import utmParamsTest from './UTMParams.test';

export default function testsuite() {
  localUnitTest();
  linkExtractorTest();
  utmParamsTest();
}