﻿// ----------------------------------------------------------------------------------
//
// Copyright Microsoft Corporation
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------------------

using System.Collections;
using System.Management.Automation;
using Microsoft.Azure.Commands.Dns.Models;
using Microsoft.Azure.Management.Dns.Models;

using ProjectResources = Microsoft.Azure.Commands.Dns.Properties.Resources;

namespace Microsoft.Azure.Commands.Dns
{
    /// <summary>
    /// Creates a new record set.
    /// </summary>
    [Cmdlet(VerbsCommon.New, "AzureRMDnsRecordSet"), OutputType(typeof(DnsRecordSet))]
    public class NewAzureDnsRecordSet : DnsBaseCmdlet
    {
        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = "The name of the records inthis record set (relative to the name of the zone and without a terminating dot).")]
        [ValidateNotNullOrEmpty]
        public string Name { get; set; }

        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = "The zone in which to create the record set (without a terminating dot).", ParameterSetName = "Fields")]
        [ValidateNotNullOrEmpty]
        public string ZoneName { get; set; }

        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = "The resource group to which the zone belongs.", ParameterSetName = "Fields")]
        [ValidateNotNullOrEmpty]
        public string ResourceGroupName { get; set; }

        [Parameter(Mandatory = true, ValueFromPipeline = true, HelpMessage = "The DnsZone object representing the zone in which to create the record set.", ParameterSetName = "Object")]
        [ValidateNotNullOrEmpty]
        public DnsZone Zone { get; set; }

        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = "The TTL value of all the records in this record set.")]
        [ValidateNotNullOrEmpty]
        public uint Ttl { get; set; }

        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = "The type of DNS records in this record set.")]
        [ValidateNotNullOrEmpty]
        public RecordType RecordType { get; set; }

        [Alias("Tags")]
        [Parameter(Mandatory = false, ValueFromPipelineByPropertyName = true, HelpMessage = "A hash table which represents resource tags.")]
        public Hashtable[] Tag { get; set; }

        [Parameter(Mandatory = false, HelpMessage = "Do not fail if the record set already exists.")]
        public SwitchParameter Overwrite { get; set; }

        [Parameter(Mandatory = false, HelpMessage = "Do not ask for confirmation.")]
        public SwitchParameter Force { get; set; }

        protected override void ProcessRecord()
        {
            string zoneName = null;
            string resourceGroupname = null;
            DnsRecordSet result = null;

            if (ParameterSetName == "Fields")
            {
                zoneName = this.ZoneName;
                resourceGroupname = this.ResourceGroupName;
            }
            else if (ParameterSetName == "Object")
            {
                zoneName = this.Zone.Name;
                resourceGroupname = this.Zone.ResourceGroupName;
            }

            if (zoneName != null && zoneName.EndsWith("."))
            {
                zoneName = zoneName.TrimEnd('.');
                this.WriteWarning(string.Format("Modifying zone name to remove terminating '.'.  Zone name used is \"{0}\".", zoneName));
            }

            ConfirmAction(
                !Overwrite.IsPresent || Force.IsPresent,
                string.Format(ProjectResources.Confirm_OverwriteRecord, this.Name, this.RecordType, zoneName),
                ProjectResources.Progress_CreatingEmptyRecordSet,
                this.Name,
                () => { result = this.DnsClient.CreateDnsRecordSet(zoneName, resourceGroupname, this.Name, this.Ttl, this.RecordType, this.Tag, this.Overwrite); });

            if (result != null)
            {
                WriteVerbose(ProjectResources.Success);
                WriteVerbose(string.Format(ProjectResources.Success_NewRecordSet, this.Name, zoneName, this.RecordType));
                WriteVerbose(string.Format(ProjectResources.Success_RecordSetFqdn, this.Name, zoneName, this.RecordType));
            }

            WriteObject(result);
        }
    }
}
