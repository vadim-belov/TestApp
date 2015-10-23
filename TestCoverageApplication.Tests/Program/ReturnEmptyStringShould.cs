using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace TestCoverageApplication.Tests
{
    [TestClass]
    public class ReturnEmptyStringShould
    {
        [TestMethod]
        public void ReturnEmptyStringWhenCalled()
        {
            string result = Program.ReturnEmptyString();
            string expected = string.Empty;

            Assert.AreEqual(expected, result);
        }
    }
}
