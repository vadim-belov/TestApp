using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace TestCoverageApplication.Tests
{
    [TestClass]
    public class GetFirstNumbersShould
    {
        [TestMethod]
        public void Return5NumbersWhen5IsPassed()
        {
            string result = Program.GetFirstNumbers(5);
            const string expected = "1 2 3 4 5";

            Assert.AreEqual(expected, result);
        }
    }
}
