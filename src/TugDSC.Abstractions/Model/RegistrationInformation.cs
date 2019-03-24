// PowerShell.org Tug DSC Pull Server
// Copyright (c) The DevOps Collective, Inc.  All rights reserved.
// Licensed under the MIT license.  See the LICENSE file in the project root for more information.

using System.ComponentModel.DataAnnotations;

namespace TugDSC.Model
{
    public class RegistrationInformation : Util.ExtDataIndexerBase
    {
        // NOTE:  DO NOT CHANGE THE ORDER OF THESE PROPERTIES!!!
        // Apparently the order of these properties is important
        // to successfully fulfill the RegKey authz requirements

        [Required]
        public CertificateInformation CertificateInformation
        { get; set; }

        [Required]
        public string RegistrationMessageType
        { get; set; }
    }
}