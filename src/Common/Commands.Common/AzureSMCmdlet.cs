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

using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.IO;
using System.Management.Automation;
using Microsoft.Azure.Common.Authentication;
using Microsoft.Azure.Common.Authentication.Models;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Microsoft.WindowsAzure.Commands.Common;
using Microsoft.WindowsAzure.Commands.Common.Properties;
using Newtonsoft.Json;
using System.Threading;
using System.Management.Automation.Host;

namespace Microsoft.WindowsAzure.Commands.Utilities.Common
{
    public abstract class AzureSMCmdlet : AzurePSCmdlet
    {
        protected static AzureSMProfile _currentProfile = null;

        [Parameter(Mandatory = false, HelpMessage = "In-memory profile.")]
        public AzureSMProfile Profile { get; set; }

        /// <summary>
        /// Sets the current profile - the profile used when no Profile is explicitly passed in.  Should be used only by
        /// Profile cmdlets and tests that need to set up a particular profile
        /// </summary>
        public static AzureSMProfile CurrentProfile 
        {
            private get
            {
                if (_currentProfile == null)
                {
                    _currentProfile = InitializeDefaultProfile();
                    SetTokenCacheForProfile(_currentProfile);
                }

                return _currentProfile;
            }

            set
            {
                SetTokenCacheForProfile(value);
                _currentProfile = value;
            }
        }

        protected static TokenCache DefaultDiskTokenCache { get; set; }

        protected static TokenCache DefaultMemoryTokenCache { get; set; }

        protected override AzureContext DefaultContext { get { return CurrentProfile.DefaultContext; } }

        static AzureSMCmdlet()
        {
            if (!TestMockSupport.RunningMocked)
            {
                AzureSession.ClientFactory.AddAction(new RPRegistrationAction());
            }

            if (!TestMockSupport.RunningMocked)
            {
                InitializeTokenCaches();
                AzureSession.DataStore = new DiskDataStore();
                SetTokenCacheForProfile(CurrentProfile);
            }
        }

        /// <summary>
        /// Create the default profile, based on the default profile path
        /// </summary>
        /// <returns>The default profile, serialized from the default location on disk</returns>
        protected static AzureSMProfile InitializeDefaultProfile()
        {
            if (!string.IsNullOrEmpty(AzureSession.ProfileDirectory) && !string.IsNullOrEmpty(AzureSession.ProfileFile))
            {
                try
                {
                   GeneralUtilities.EnsureDefaultProfileDirectoryExists();
                   return new AzureSMProfile(Path.Combine(AzureSession.ProfileDirectory, AzureSession.ProfileFile));
                }
                catch
                {
                    // swallow exceptions in creating the profile from disk
                }
            }

            return new AzureSMProfile();
        }

        protected static void InitializeTokenCaches()
        {
            DefaultMemoryTokenCache = TokenCache.DefaultShared;
            if (!string.IsNullOrWhiteSpace(AzureSession.ProfileDirectory) &&
                !string.IsNullOrWhiteSpace(AzureSession.TokenCacheFile))
            {
                GeneralUtilities.EnsureDefaultProfileDirectoryExists();
                DefaultDiskTokenCache = new ProtectedFileTokenCache(Path.Combine(AzureSession.ProfileDirectory, AzureSession.TokenCacheFile));
            }
            else
            {
                DefaultDiskTokenCache = DefaultMemoryTokenCache;
            }
        }

        /// <summary>
        /// Update the token cache when setting the profile
        /// </summary>
        /// <param name="profile"></param>
        protected static void SetTokenCacheForProfile(AzureSMProfile profile)
        {
            var defaultProfilePath = Path.Combine(AzureSession.ProfileDirectory, AzureSession.ProfileFile);
            if (string.Equals(profile.ProfilePath, defaultProfilePath, StringComparison.OrdinalIgnoreCase))
            {
                AzureSession.TokenCache = DefaultDiskTokenCache;
            }
            else
            {
                AzureSession.TokenCache = DefaultMemoryTokenCache;
            }
        }

        protected override void SaveDataCollectionProfile()
        {
            if (_dataCollectionProfile == null)
            {
                InitializeDataCollectionProfile();
            }

            string fileFullPath = Path.Combine(AzureSession.ProfileDirectory, AzurePSDataCollectionProfile.DefaultFileName);
            var contents = JsonConvert.SerializeObject(_dataCollectionProfile);
            AzureSession.DataStore.WriteFile(fileFullPath, contents);
            WriteWarning(string.Format(Resources.DataCollectionSaveFileInformation, fileFullPath));
        }

        protected override void PromptForDataCollectionProfileIfNotExists()
        {
            // Initialize it from the environment variable or profile file.
            InitializeDataCollectionProfile();

            if (!_dataCollectionProfile.EnableAzureDataCollection.HasValue && CheckIfInteractive())
            {
                WriteWarning(Resources.DataCollectionPrompt);

                const double timeToWaitInSeconds = 60;
                var status = string.Format(Resources.DataCollectionConfirmTime, timeToWaitInSeconds);
                ProgressRecord record = new ProgressRecord(0, Resources.DataCollectionActivity, status);

                var startTime = DateTime.Now;
                var endTime = DateTime.Now;
                double elapsedSeconds = 0;

                while (!this.Host.UI.RawUI.KeyAvailable && elapsedSeconds < timeToWaitInSeconds)
                {
                    Thread.Sleep(TimeSpan.FromMilliseconds(10));
                    endTime = DateTime.Now;

                    elapsedSeconds = (endTime - startTime).TotalSeconds;
                    record.PercentComplete = ((int)elapsedSeconds * 100 / (int)timeToWaitInSeconds);
                    WriteProgress(record);
                }

                bool enabled = false;
                if (this.Host.UI.RawUI.KeyAvailable)
                {
                    KeyInfo keyInfo = this.Host.UI.RawUI.ReadKey(ReadKeyOptions.NoEcho | ReadKeyOptions.AllowCtrlC | ReadKeyOptions.IncludeKeyDown);
                    enabled = (keyInfo.Character == 'Y' || keyInfo.Character == 'y');
                }

                _dataCollectionProfile.EnableAzureDataCollection = enabled;

                WriteWarning(enabled ? Resources.DataCollectionConfirmYes : Resources.DataCollectionConfirmNo);

                SaveDataCollectionProfile();
            }
        }

        protected override void InitializeQosEvent()
        {
            QosEvent = new AzurePSQoSEvent()
            {
                CmdletType = this.GetType().Name,
                IsSuccess = true,
            };

            if (this.Profile != null && this.Profile.DefaultSubscription != null)
            {
                QosEvent.Uid = MetricHelper.GenerateSha256HashString(
                    this.Profile.DefaultSubscription.Id.ToString());
            }
            else
            {
                QosEvent.Uid = "defaultid";
            }
        }

        /// <summary>
        /// Cmdlet begin process. Write to logs, setup Http Tracing and initialize profile
        /// </summary>
        protected override void BeginProcessing()
        {
            InitializeProfile();
            base.BeginProcessing();
        }

        /// <summary>
        /// Ensure that there is a profile for the command
        /// </summary>
        protected  virtual void InitializeProfile()
        {
            if (Profile == null)
            {
                Profile = AzureSMCmdlet.CurrentProfile;
            }

            SetTokenCacheForProfile(Profile);
        }

        public virtual void ExecuteCmdlet()
        {
            // Do nothing.
        }

        protected override void ProcessRecord()
        {
            try
            {
                base.ProcessRecord();
                ExecuteCmdlet();
            }
            catch (Exception ex)
            {
                WriteExceptionError(ex);
            }
        }
    }
}
