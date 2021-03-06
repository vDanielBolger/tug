using System;
using Microsoft.Extensions.Logging;
using TugDSC.Ext;
using TugDSC.Server.Util;

namespace TugDSC.Server.Providers
{
    public class IntegTestDscHandlerProvider : BasicDscHandlerProvider
    {
        private static readonly ProviderInfo MY_INFO = new ProviderInfo("integTest");

        public override ProviderInfo Describe() => MY_INFO;

        public IntegTestDscHandlerProvider(
                ILogger<IntegTestDscHandlerProvider> pLogger,
                ILogger<IntegTestDscHandler> hLogger,
                ChecksumAlgorithmManager checksumManager,
                ChecksumHelper checksumHelper)
            : base(pLogger, hLogger, checksumManager, checksumHelper)
        {
            Console.WriteLine("CONSTRUCTING INTEG-TEST HANDLER PROVIDER");
        }

        protected override BasicDscHandler ConstructHandler()
        {
            return new IntegTestDscHandler();
        }
    }
}
