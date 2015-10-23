using System.Collections.Generic;
using System.Linq;

namespace TestCoverageApplication
{
    public class Program
    {
        static void Main(string[] args)
        {
            GetFirstNumbers(10);
        }

        public static string GetFirstNumbers(int count)
        {
            int currentNumber = 1;
            //

            string text = string.Empty;

            new int[count]
                .Select(p =>
                {
                    text += " " + currentNumber++;
                    return true;
                })
                .ToList();

            return text
                .TrimStart();
        }

        public static string ReturnEmptyString()
        {
            return string.Empty;
        }

        private string NotUsedMethod()
        {
            new List<int>()
                .Where(p => p > 0)
                .ToArray()
                .ToList()
                .Any(p => p < 0);

            return null;
        }
    }
}
