<#PSScriptInfo
.VERSION 1.0.20190625
.GUID 94a29c6e-40b3-4988-b19a-65769b8e6875
.AUTHOR Ronnie Smith
.COMPANYNAME Dynamic Quest
.COPYRIGHT 
.TAGS dashimo 
.LICENSEURI 
.PROJECTURI 
.ICONURI 
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES 
Version 1.0.20190625
	Initial Build
#>

<#
.DESCRIPTION


.USAGE

#>

Param(
	$SaveLocation = 'C:\Admin\DQ\ADHealthCheck'
)
Write-Host ("[INFO] Checking PowerShell Version")
$PSMinimumVersion = [Version]'5.1'
if ($PSMinimumVersion -gt $PSVersionTable.PSVersion) {
	throw '[FAILURE] This script requires PowerShell $PSMinimumVersion or higher. Go to https://docs.microsoft.com/en-us/powershell/wmf/ to download and install the latest version.'
} else {
	Write-Information ("[SUCCESS] PowerShell Version $($PSVersionTable.PSVersion)") -InformationAction Continue
}
Write-Information ("") -InformationAction Continue
Write-Information ("[INFO] Checking PowerShell Modules") -InformationAction Continue
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
$Modules = @('ActiveDirectory', 'Dashimo', 'PSWinReportingV2', 'PSWinDocumentation', 'PSWinDocumentation.AD')
foreach ($Module in $Modules) {
	if (! (Get-Module -ListAvailable $Module)) {
		Write-Information ("[INFO] PowerShell Module $Module Missing") -InformationAction Continue
		Install-Module $Module -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		if (! (Get-Module -ListAvailable $Module)) {
			throw "[FAILURE] PowerShell Module $Module Installation Failed"
		} else {
			Write-Information ("[SUCCESS] PowerShell Module $Module $((Get-Module $Module).Version) Installed") -InformationAction Continue
		}
	}
	if (! (Get-Module $Module)) {
		Update-Module $Module -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		Import-Module $Module -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		if (! (Get-Module $Module)) {
			throw "[FAILURE] PowerShell Module $Module Loading Failed"
		} else {
			Write-Information ("[SUCCESS] PowerShell Module $Module $((Get-Module $Module).Version) Loaded") -InformationAction Continue
		}
	} else {
		Write-Information ("[INFO] PowerShell Module $Module $((Get-Module $Module).Version) Already Loaded") -InformationAction Continue
	}
}
Write-Information ("") -InformationAction Continue
Write-Information ("[INFO] Gathering Domain Controllers") -InformationAction Continue
$allDCs = (Get-ADForest).Domains | %{ Get-ADDomainController -Filter * -Server $_ }
Write-Information ("") -InformationAction Continue
Write-Information ("[INFO] Gathering Forest Data") -InformationAction Continue
if ($null -eq $DataSetForest -or $null -eq $RunTime) {
	$RunTime = Get-Date
	$DataSetForest = Get-WinADForestInformation -Verbose -DontRemoveEmpty -PasswordQuality -Splitter '`r`n'
}
Write-Information ("") -InformationAction Continue
Write-Information ("[INFO] Gathering Event Data") -InformationAction Continue
if ($null -eq $DataSetEvents) {
	$DataSetEvents = Find-Events -Report ADUserChanges, ADUserStatus, ADUserLockouts, ADComputerCreatedChanged, ADComputerDeleted, ADGroupChanges, ADGroupMembershipChanges, ADGroupCreateDelete, ADOrganizationalUnitChangesDetailed, ADGroupPolicyChanges -Servers ($allDCs).HostName -DateFrom (Get-Date).AddDays(-60) -DateTo (Get-Date)
}
Write-Information ("") -InformationAction Continue
Write-Information ("[INFO] Creating Save Location $SaveLocation") -InformationAction Continue
New-Item -ItemType Directory -Path $SaveLocation -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
Write-Information ("") -InformationAction Continue
Write-Information ("[INFO] Generating Dashboard") -InformationAction Continue
$ReportTime = Get-Date
Dashboard -Name $((Get-ADForest).Name) -FilePath $SaveLocation\ADDashboard_$((Get-ADForest).Name)_$(Get-Date $ReportTime -Format yyyy-MM-ddTHH-mm-ss).html {
	TabOptions -SlimTabs -SelectorColor DodgerBlue -Transition
	Tab -Name 'Forest' -IconSolid tree {
		Section -Name 'Forest Information' -Collapsable {
			Panel -Invisible {
				Write-Information ("[INFO] Table ForestInformation") -InformationAction Continue
				Table -DataTable $DataSetForest.ForestInformation -PreContent {'<div style="text-align:center;font-weight:bold">Forest Information</div>'} -PostContent {
						'<div>
							<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Forest Functional Level means forest is on a supported version.</span><br>
							<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE Forest Functional Level means forest is on a version in extended support.</span><br>
							<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Forest Functional Level means forest is on an unsupported version.</span>
						</div>'
					} -Buttons @() -DisableColumnReorder -DisableInfo -DisableOrdering -DisablePaging -DisableSearch -DisableSelect -DisableStateSave -HideFooter -Verbose {
					TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2019Forest' -Color DarkGreen -BackgroundColor PaleGreen -Row
					TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2016Forest' -Color DarkGreen -BackgroundColor PaleGreen -Row
					TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2012R2Forest' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod -Row
					TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2012Forest' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod -Row
					TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2008R2Forest' -Color DarkRed -BackgroundColor Pink -Row
					TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2008Forest' -Color DarkRed -BackgroundColor Pink -Row
					TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2003Forest' -Color DarkRed -BackgroundColor Pink -Row
					TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2000Forest' -Color DarkRed -BackgroundColor Pink -Row
				}
			}
			Panel -Invisible {
				Write-Information ("[INFO] Table ForestFSMO") -InformationAction Continue
				Table -DataTable $DataSetForest.ForestFSMO -PreContent {'<div style="text-align:center;font-weight:bold">Forest FSMO Roles</div>'} -Buttons @() -DisableColumnReorder -DisableInfo -DisableOrdering -DisablePaging -DisableSearch -DisableSelect -DisableStateSave -HideFooter -Verbose
			}
		}
		Section -Name 'Forest Domain Controllers' -Collapsable {
			Panel -Invisible {
				Write-Information ("[INFO] Table ForestDomainControllers") -InformationAction Continue
				Table -DataTable $DataSetForest.ForestDomainControllers -PostContent {
						'<div>
							<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Forest Domain Controller field means value is expected or to highlight field.</span><br>
							<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE Forest Domain Controller field means value may not be expected.</span><br>
							<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Forest Domain Controller field means value is unexpected.</span>
						</div>'
					} -Buttons @() -PagingOptions @(5, 10, 20) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					TableConditionalFormatting -Name 'IsGlobalCatalog' string eq -Value 'False' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'IsGlobalCatalog' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'IsReadOnly' string eq -Value 'True' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'IsReadOnly' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'SchemaMaster' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'DomainNamingMasterMaster' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'PDCEmulator' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'RIDMaster' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'InfrastructureMaster' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'LdapPort' number ge -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'LdapPort' number eq -Value 389 -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'SslPort' number ge -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'SslPort' number eq -Value 636 -Color DarkGreen -BackgroundColor PaleGreen
				}
			}
		}
		Section -Name 'Forest Settings' -Collapsable {
			Panel -Invisible {
				Write-Information ("[INFO] Table ForestOptionalFeatures") -InformationAction Continue
				Table -DataTable $DataSetForest.ForestOptionalFeatures -PreContent {'<div style="text-align:center;font-weight:bold">Forest Optional Features</div>'} -PostContent {
						'<div>
							<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Forest Optional Features are healthy.</span><br>
							<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Forest Optional Features should be reviewed and enabled if possible.</span>
						</div>'
					} -Buttons @() -DisableColumnReorder -DisableInfo -DisableOrdering -DisablePaging -DisableSearch -DisableSelect -DisableStateSave -HideFooter -Verbose {
					TableConditionalFormatting -Name 'Value' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink -Row
					TableConditionalFormatting -Name 'Value' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen -Row
				}
			}
			Panel -Invisible {
				Write-Information ("[INFO] Table ForestUPNSuffixes") -InformationAction Continue
				Table -DataTable $DataSetForest.ForestUPNSuffixes -PreContent {'<div style="text-align:center;font-weight:bold">Forest UPN Suffixes</div>'} -Buttons @() -PagingOptions @(3, 5, 10, 20) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					}
			}
			Panel -Invisible {
				Write-Information ("[INFO] Table ForestSPNSuffixes") -InformationAction Continue
				Table -DataTable $DataSetForest.ForestSPNSuffixes -PreContent {'<div style="text-align:center;font-weight:bold">Forest SPN Suffixes</div>'} -Buttons @() -PagingOptions @(3, 5, 10, 20) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
				}
			}
		}
		Section -Name 'Sites / Subnets / SiteLinks' -Collapsable {
			Panel -Invisible {
				Write-Information ("[INFO] Table ForestSites") -InformationAction Continue
				Table -DataTable $DataSetForest.ForestSites -PreContent {'<div style="text-align:center;font-weight:bold">Forest Sites</div>'} -PostContent {
						'<div>
							<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Forest Sites are protected from accidental deletion.</span><br>
							<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Forest Sites are not protected from accidental deletion.</span>
						</div>'
					} -Buttons @() -PagingOptions @(3, 5, 10, 20) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					TableConditionalFormatting -Name 'ProtectedFromAccidentalDeletion' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink -Row
					TableConditionalFormatting -Name 'ProtectedFromAccidentalDeletion' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen -Row
				}
			}
			Panel -Invisible {
				Write-Information ("[INFO] Table ForestSubnets") -InformationAction Continue
				Table -DataTable $DataSetForest.ForestSubnets -PreContent {'<div style="text-align:center;font-weight:bold">Forest Subnets</div>'} -PostContent {
						'<div>
							<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Forest Subnets are protected from accidental deletion.</span><br>
							<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Forest Subnets are not protected from accidental deletion.</span>
						</div>'
					} -Buttons @() -PagingOptions @(3, 5, 10, 20) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					TableConditionalFormatting -Name 'ProtectedFromAccidentalDeletion' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink -Row
					TableConditionalFormatting -Name 'ProtectedFromAccidentalDeletion' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen -Row
				}
			}
			Panel -Invisible {
				Write-Information ("[INFO] Table ForestSiteLinks") -InformationAction Continue
				Table -DataTable $DataSetForest.ForestSiteLinks -PreContent {'<div style="text-align:center;font-weight:bold">Forest Site Links</div>'} -PostContent {
						'<div>
							<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Forest Site Links are protected from accidental deletion.</span><br>
							<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Forest Site Links are not protected from accidental deletion.</span>
						</div>'
					} -Buttons @() -PagingOptions @(3, 5, 10, 20) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					TableConditionalFormatting -Name 'ProtectedFromAccidentalDeletion' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink -Row
					TableConditionalFormatting -Name 'ProtectedFromAccidentalDeletion' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen -Row
				}
			}
		}
		Section -Name 'Replication' -Collapsable {
			Panel -Invisible {
				$DataSetForest['ForestReplicationTable'] = $DataSetForest.ForestReplication | Select-Object Server, Partition, Partner, @{Name='LastReplicationAttempt'; Expression={Get-Date $_.LastReplicationAttempt -Format s}}, LastReplicationResult, @{Name='LastReplicationSuccess'; Expression={Get-Date $_.LastReplicationSuccess -Format s}}, ConsecutiveReplicationFailures
				Write-Information ("[INFO] Table ForestReplicationTable") -InformationAction Continue
				Table -DataTable $DataSetForest.ForestReplicationTable -PostContent {
						'<div>
							<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Forest Replicaton rows are healthy.</span><br>
							<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Forest Replicaton fields or rows are unhealthy.</span>
						</div>'
					} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					TableConditionalFormatting -Name 'LastReplicationSuccess' string ge -Value (Get-Date ($RunTime).AddHours(-1) -Format s) -Color DarkGreen -BackgroundColor PaleGreen -Row
					TableConditionalFormatting -Name 'LastReplicationSuccess' string lt -Value (Get-Date ($RunTime).AddHours(-1) -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod -Row
					TableConditionalFormatting -Name 'LastReplicationSuccess' string lt -Value (Get-Date ($RunTime).AddDays(-1) -Format s) -Color DarkRed -BackgroundColor Pink -Row
					TableConditionalFormatting -Name 'LastReplicationAttempt' string ge -Value (Get-Date ($RunTime).AddHours(-1) -Format s) -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'LastReplicationAttempt' string lt -Value (Get-Date ($RunTime).AddHours(-1) -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'LastReplicationAttempt' string lt -Value (Get-Date ($RunTime).AddDays(-1) -Format s) -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'LastReplicationResult' number eq -Value 0 -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'LastReplicationResult' number gt -Value 0 -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'LastReplicationResult' number lt -Value 0 -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'ConsecutiveReplicationFailures' number eq -Value 0 -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'ConsecutiveReplicationFailures' number gt -Value 0 -Color DarkRed -BackgroundColor Pink
				}
			}
		}
	}
	foreach ($Domain in $DataSetForest.FoundDomains.Keys) {
		$Global:Domain = $Domain
		Tab -Name $Domain -IconSolid sitemap {
			Section -Name 'Domain Information' -Collapsable {
				Container {
					Panel -Invisible {
						$DataSetForest.FoundDomains.$Domain['DomainInformationTable'] = @(
							[PSCustomObject]@{Name='Name'; Value=$DataSetForest.FoundDomains.$Domain.DomainInformation.Name}
							[PSCustomObject]@{Name='NetBIOS Name'; Value=$DataSetForest.FoundDomains.$Domain.DomainInformation.NetBIOSName}
							[PSCustomObject]@{Name='Domain Distinguished Name'; Value=$DataSetForest.FoundDomains.$Domain.DomainInformation.DistinguishedName}
							[PSCustomObject]@{Name='Domain Functional Level'; Value=$DataSetForest.FoundDomains.$Domain.DomainInformation.DomainMode}
							[PSCustomObject]@{Name='Computers Container'; Value=$DataSetForest.FoundDomains.$Domain.DomainInformation.ComputersContainer}
							[PSCustomObject]@{Name='Users Container'; Value=$DataSetForest.FoundDomains.$Domain.DomainInformation.UsersContainer}
						)
						Write-Information ("[INFO] Table $Domain DomainInformationTable") -InformationAction Continue
						Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainInformationTable -PreContent {'<div style="text-align:center;font-weight:bold">Domain Information</div>'} -PostContent {
								'<div>
									<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Domain Functional Level means forest is on a supported version.</span><br>
									<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE Domain Functional Level means forest is on a version in extended support.</span><br>
									<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Domain Functional Level means forest is on an unsupported version.</span>
								</div>'
							} -Buttons @() -DisableColumnReorder -DisableInfo -DisableOrdering -DisablePaging -DisableSearch -DisableSelect -DisableStateSave -HideFooter -Verbose {
							TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2000Domain' -Color DarkRed -BackgroundColor Pink -Row
							TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2003Domain' -Color DarkRed -BackgroundColor Pink -Row
							TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2008Domain' -Color DarkRed -BackgroundColor Pink -Row
							TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2008R2Domain' -Color DarkRed -BackgroundColor Pink -Row
							TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2012Domain' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod -Row
							TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2012R2Domain' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod -Row
							TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2016Domain' -Color DarkGreen -BackgroundColor PaleGreen -Row
							TableConditionalFormatting -Name 'Value' string eq -Value 'Windows2019Domain' -Color DarkGreen -BackgroundColor PaleGreen -Row
						}
					}
				}
				Container {
					Panel -Invisible {
						Write-Information ("[INFO] Table $Domain DomainFSMO") -InformationAction Continue
						Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainFSMO -PreContent {'<div style="text-align:center;font-weight:bold">Domain FSMO Roles</div>'} -Buttons @() -DisableColumnReorder -DisableInfo -DisableOrdering -DisablePaging -DisableSearch -DisableSelect -DisableStateSave -HideFooter -Verbose
					}
					if ($DataSetForest.FoundDomains.$Domain.DomainTrusts.SID.Count -gt 0) {
						Panel -Invisible {
							$DataSetForest.FoundDomains.$Domain['DomainTrustsTable'] = $DataSetForest.FoundDomains.$Domain.DomainTrusts | Select-Object 'Trust Source', 'Trust Target', 'Trust Direction', 'Trust Status'
							Write-Information ("[INFO] Table $Domain DomainTrustsTable") -InformationAction Continue
							Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainTrustsTable -PreContent {'<div style="text-align:center;font-weight:bold">Domain Trusts</div>'} -PostContent {
									'<div>
										<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Domain Trusts means trust status is OK.</span><br>
										<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Domain Trusts means trust is unhealthy.</span>
									</div>'
								} -Buttons @() -DisableColumnReorder -DisableInfo -DisableOrdering -DisablePaging -DisableSearch -DisableSelect -DisableStateSave -HideFooter -Verbose {
								TableConditionalFormatting -Name 'Trust Status' string ge -Value '' -Color DarkRed -BackgroundColor Pink -Row
								TableConditionalFormatting -Name 'Trust Status' string eq -Value 'OK' -Color DarkGreen -BackgroundColor PaleGreen -Row
							}
						}
					}
				}
			}
			Section -Name 'Domain Controllers' -Collapsable {
				Panel -Invisible {
					Write-Information ("[INFO] Table $Domain DomainControllers") -InformationAction Continue
					Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainControllers -PostContent {
							'<div>
								<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Domain Controller field means value is expected or to highlight field.</span><br>
								<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE Domain Controller field means value may not be expected.</span><br>
								<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Forest Controller field means value is unexpected.</span><br>
								<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Operating System means OS is on a supported version.</span><br>
								<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE Operating System means OS is on a version in extended support.</span><br>
								<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Operating System means OS is on an unsupported version.</span>
							</div>'
						} -Buttons @() -PagingOptions @(5, 10, 20) -DisableStateSave -HideFooter -Verbose {
						TableButtonCSV
						TableButtonPageLength
						TableConditionalFormatting -Name 'Operating System' string ge -Value 'Windows Server 2000' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Operating System' string ge -Value 'Windows Server 2003' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Operating System' string ge -Value 'Windows Server 2008' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Operating System' string ge -Value 'Windows Server 2012' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'Operating System' string ge -Value 'Windows Server 2012 R2' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'Operating System' string ge -Value 'Windows Server 2016' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Operating System' string ge -Value 'Windows Server 2019' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Global Catalog?' string eq -Value 'False' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'Global Catalog?' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Read Only?' string eq -Value 'True' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'Read Only?' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Ldap Port' number ge -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'Ldap Port' number eq -Value 389 -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Ssl Port' number ge -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'Ssl Port' number eq -Value 636 -Color DarkGreen -BackgroundColor PaleGreen
					}
				}
			}
			Section -Name 'Default Password Policy' -Collapsable {
				Panel -Invisible {
					$DataSetForest.FoundDomains.$Domain['DomainDefaultPasswordPolicyTable'] = @(
						[PSCustomObject]@{Policy=$DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicy.'Distinguished Name';
							'Password History Count'=$DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicy.'Password History Count';
							'Max Password Age'=$DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicy.'Max Password Age';
							'Min Password Age'=$DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicy.'Min Password Age';
							'Min Password Length'=$DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicy.'Min Password Length';
							'Complexity Enabled'=$DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicy.'Complexity Enabled';
							'Reversible Encryption Enabled'=$DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicy.'Reversible Encryption Enabled';
							'Lockout Duration'=$DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicy.'Lockout Duration';
							'Lockout Threshold'=$DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicy.'Lockout Threshold';
							'Lockout Observation Window'=$DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicy.'Lockout Observation Window'
						}
						[PSCustomObject]@{Policy='Recommendation';
							'Password History Count'='>= 24 passwords remembered';
							'Max Password Age'='<= 60 days';
							'Min Password Age'='>= 1 days';
							'Min Password Length'='>= 14 characters';
							'Complexity Enabled'=$true;
							'Reversible Encryption Enabled'=$false;
							'Lockout Duration'='>= 15 minutes';
							'Lockout Threshold'='<= 10 invalid logon attempts';
							'Lockout Observation Window'='>= 15 minutes'
						}
					)
					Write-Information ("[INFO] Table $Domain DomainDefaultPasswordPolicyTable") -InformationAction Continue
					Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainDefaultPasswordPolicyTable -PostContent {
							'<div>
								<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Default Password Policy field means value meets or exceeds recommendation.</span><br>
								<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Default Password Policy field means value does not meet recommendation.</span>
							</div>'
						} -Buttons @() -DisableColumnReorder -DisableInfo -DisableOrdering -DisablePaging -DisableSearch -DisableSelect -DisableStateSave -HideFooter -Verbose {
						TableConditionalFormatting -Name 'Complexity Enabled' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Complexity Enabled' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Lockout Duration' number lt -Value 15 -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Lockout Duration' number ge -Value 15 -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Lockout Observation Window' number lt -Value 15 -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Lockout Observation Window' number ge -Value 15 -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Lockout Threshold' number gt -Value 10 -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Lockout Threshold' number le -Value 10 -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Lockout Threshold' number eq -Value 0 -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Max Password Age' number gt -Value 60 -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Max Password Age' number le -Value 60 -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Max Password Age' number eq -Value 0 -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Min Password Length' number lt -Value 14 -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Min Password Length' number ge -Value 14 -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Min Password Age' number lt -Value 1 -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Min Password Age' number ge -Value 1 -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Password History Count' number lt -Value 24 -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Password History Count' number ge -Value 24 -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Reversible Encryption Enabled' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Reversible Encryption Enabled' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Policy' string eq -Value 'Recommendation' -Color DarkGreen -BackgroundColor PaleGreen -Row
					}
				}
			}
			Section -Name 'Password Stats' -Collapsable {
				$DataSetForest.FoundDomains.$Domain['DomainPasswordStatsTable'] = Format-TransposeTable -Object $DataSetForest.FoundDomains.$Domain.DomainPasswordStats
				Write-Information ("[INFO] Table $Domain DomainPasswordStatsTable") -InformationAction Continue
				Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainPasswordStatsTable -PostContent {
						'<div>
							<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Password Stats field means value is 0.</span><br>
							<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE Password Stats field means value is greater than 0.</span><br>
						</div>'
					} -Buttons @() -DisableColumnReorder -DisableInfo -DisableOrdering -DisablePaging -DisableSearch -DisableSelect -DisableStateSave -HideFooter -Verbose {
					TableConditionalFormatting -Name 'Clear Text Passwords' number gt -Value -1 -Color DarkGreen -BackgroundColor PaleGreen -Row
					TableConditionalFormatting -Name 'Clear Text Passwords' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'LM Hashes' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Empty Passwords' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Weak Passwords' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Weak Passwords Enabled' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Weak Passwords Disabled' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Weak Passwords (HASH)' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Weak Passwords (HASH) Enabled' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Weak Passwords (HASH) Disabled' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Default Computer Passwords' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Password Not Required' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Password Never Expires' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'AES Keys Missing' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'PreAuth Not Required' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'DES Encryption Only' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Delegatable Admins' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Duplicate Password Users' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Duplicate Password Grouped' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
				}
			}
			$PasswordStatsRow = [PSCustomObject]@{
				1 = @(
					[PSCustomObject]@{Name='Clear Text Passwords'; Table='DomainPasswordClearTextPasswordTable'; Dataset='DomainPasswordClearTextPassword'}
					[PSCustomObject]@{Name='Empty Passwords'; Table='DomainPasswordEmptyPasswordTable'; Dataset='DomainPasswordEmptyPassword'}
					[PSCustomObject]@{Name='Password Not Required'; Table='DomainPasswordPasswordNotRequiredTable'; Dataset='DomainPasswordPasswordNotRequired'}
					[PSCustomObject]@{Name='Password Never Expires'; Table='DomainPasswordPasswordNeverExpiresTable'; Dataset='DomainPasswordPasswordNeverExpires'}
					[PSCustomObject]@{Name='Default Computer Passwords'; Table='DomainPasswordDefaultComputerPasswordTable'; Dataset='DomainPasswordDefaultComputerPassword'}
				)
				2 = @(
					[PSCustomObject]@{Name='Weak Passwords'; Table='DomainPasswordWeakPasswordTable'; Dataset='DomainPasswordWeakPassword'}
					[PSCustomObject]@{Name='Weak Passwords Enabled'; Table='DomainPasswordWeakPasswordEnabledTable'; Dataset='DomainPasswordWeakPasswordEnabled'}
					[PSCustomObject]@{Name='Weak Passwords Disabled'; Table='DomainPasswordWeakPasswordDisabledTable'; Dataset='DomainPasswordWeakPasswordDisabled'}
					[PSCustomObject]@{Name='Weak Passwords (HASH)'; Table='DomainPasswordHashesWeakPasswordTable'; Dataset='DomainPasswordHashesWeakPassword'}
					[PSCustomObject]@{Name='Weak Passwords (HASH) Enabled'; Table='DomainPasswordHashesWeakPasswordEnabledTable'; Dataset='DomainPasswordHashesWeakPasswordEnabled'}
					[PSCustomObject]@{Name='Weak Passwords (HASH) Disabled'; Table='DomainPasswordHashesWeakPasswordDisabledTable'; Dataset='DomainPasswordHashesWeakPasswordDisabled'}
				)
				3 = @(
					[PSCustomObject]@{Name='LM Hashes'; Table='DomainPasswordLMHashTable'; Dataset='DomainPasswordLMHash'}
					[PSCustomObject]@{Name='AES Keys Missing'; Table='DomainPasswordAESKeysMissingTable'; Dataset='DomainPasswordAESKeysMissing'}
					[PSCustomObject]@{Name='PreAuth Not Required'; Table='DomainPasswordPreAuthNotRequiredTable'; Dataset='DomainPasswordPreAuthNotRequired'}
					[PSCustomObject]@{Name='DES Encryption Only'; Table='DomainPasswordDESEncryptionOnlyTable'; Dataset='DomainPasswordDESEncryptionOnly'}
				)
				4 = @(
					[PSCustomObject]@{Name='Delegatable Admins'; Table='DomainPasswordDelegatableAdminsTable'; Dataset='DomainPasswordDelegatableAdmins'}
					[PSCustomObject]@{Name='Duplicate Password Users'; Table='DomainPasswordDuplicatePasswordGroupsTable'; Dataset='DomainPasswordDuplicatePasswordGroups'}
				)
			}
			$Counter = 0
			for ($Row = 1; $Row -le 4; $Row++) {foreach ($Stat in $PasswordStatsRow.$Row) {$Counter += $DataSetForest.FoundDomains.$Domain.($Stat.Dataset).Count}}
			if ($Counter -gt 0) {
				Section -Name 'Password Stats Breakdown' -Collapsable {
					for ($Row = 1; $Row -le 4; $Row++) {
						$Counter = 0
						foreach ($Stat in $PasswordStatsRow.$Row) {$Counter += $DataSetForest.FoundDomains.$Domain.($Stat.Dataset).Count}
						if ($Counter -gt 0) {
							Container {
								foreach ($Stat in $PasswordStatsRow.$Row) {
									if ($DataSetForest.FoundDomains.$Domain.($Stat.Dataset).Count -gt 0) {
										Panel -Invisible {
											$DataSetForest.FoundDomains.$Domain[$Stat.Table] = $DataSetForest.FoundDomains.$Domain.($Stat.Dataset) | Sort-Object @{Expression={if ($Stat.Name -eq 'Duplicate Password Users') { $_.'Duplicate Group' } else {$Stat.Name}}; Ascending=$true}, @{Expression='Enabled'; Descending=$true}, CanonicalName | Select-Object @{Name='Stat'; Expression={if ($Stat.Name -eq 'Duplicate Password Users') { $_.'Duplicate Group' } else {$Stat.Name}}}, Name, @{Name='Username'; Expression={$_.SamAccountName}}, Enabled, Protected, @{Name='Account Type'; Expression={
												switch -Wildcard ($_.CanonicalName) {
													'*Microsoft Exchange System Objects*' {'Exchange'; break}
													default {''}
												}}}, @{Name='LastLogonDate'; Expression={Get-Date $_.LastLogonDate -Format s}}, PasswordNeverExpires, PasswordNotRequired, CanonicalName
											Write-Information ("[INFO] Table $Domain $($Stat.Name)") -InformationAction Continue
											Table -DataTable $DataSetForest.FoundDomains.$Domain.($Stat.Table) -PreContent {'<div style="text-align:center;font-weight:bold">' + $Stat.Name + '</div>'} -Buttons @() -PagingOptions @(3, 5, 10, 20) -DisableStateSave -HideFooter -Verbose {
												TableButtonCSV
												TableButtonPageLength
												TableConditionalFormatting -Name 'Account Type' string eq -Value 'Exchange' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod -Row
												TableConditionalFormatting -Name 'Enabled' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
												TableConditionalFormatting -Name 'Protected' string eq -Value 'False' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
												TableConditionalFormatting -Name 'Protected' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
												TableConditionalFormatting -Name 'LastLogonDate' string eq -Value '' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
												TableConditionalFormatting -Name 'LastLogonDate' string lt -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
												TableConditionalFormatting -Name 'LastLogonDate' string ge -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGreen -BackgroundColor PaleGreen
												TableConditionalFormatting -Name 'PasswordNeverExpires' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
												TableConditionalFormatting -Name 'PasswordNeverExpires' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
												TableConditionalFormatting -Name 'PasswordNotRequired' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
												TableConditionalFormatting -Name 'PasswordNotRequired' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
												TableConditionalFormatting -Name 'Enabled' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink -Row
											}
										}
									}
								}
							}
						}
					}
				}
			}
			Section -Name 'Administrators' -Collapsable {
				$AdminStats = @(
					[PSCustomObject]@{Name='Administrators'; Table='AdministratorsTable'}
					[PSCustomObject]@{Name='Domain Admins'; Table='DomainAdministratorsTable'}
					[PSCustomObject]@{Name='Enterprise Admins'; Table='DomainEnterpriseAdministratorsTable'}
					[PSCustomObject]@{Name='Schema Admins'; Table='SchemaAdminsTable'}
				)
				$DataSetForest.FoundDomains.$Domain['AdministratorsTable'] = $DataSetForest.FoundDomains.$Domain.DomainGroupsMembersRecursive | Where-Object {$_.'Group SID' -eq 'S-1-5-32-544'} | Sort-Object @{Expression='Enabled'; Descending=$true}, CanonicalName | Select-Object Name, @{Name='Username'; Expression={$_.'Sam Account Name'}}, Enabled, Protected, @{Name='LastLogonDate'; Expression={Get-Date $_.LastLogonDate -Format s}}, PasswordNeverExpires, PasswordNotRequired, BadLogonCount, @{Name='LastBadPasswordAttempt'; Expression={Get-Date $_.LastBadPasswordAttempt -Format s}}, @{Name='Created'; Expression={Get-Date $_.Created -Format s}}, @{Name='Modified'; Expression={Get-Date $_.Modified -Format s}}, @{Name='AccountExpirationDate'; Expression={Get-Date $_.AccountExpirationDate -Format s}}, CanonicalName
				$DataSetForest.FoundDomains.$Domain['DomainAdministratorsTable'] = $DataSetForest.FoundDomains.$Domain.DomainAdministratorsRecursive | Sort-Object @{Expression='Enabled'; Descending=$true}, CanonicalName | Select-Object Name, @{Name='Username'; Expression={$_.'Sam Account Name'}}, Enabled, Protected, @{Name='LastLogonDate'; Expression={Get-Date $_.LastLogonDate -Format s}}, PasswordNeverExpires, PasswordNotRequired, BadLogonCount, @{Name='LastBadPasswordAttempt'; Expression={Get-Date $_.LastBadPasswordAttempt -Format s}}, @{Name='Created'; Expression={Get-Date $_.Created -Format s}}, @{Name='Modified'; Expression={Get-Date $_.Modified -Format s}}, @{Name='AccountExpirationDate'; Expression={Get-Date $_.AccountExpirationDate -Format s}}, CanonicalName
				$DataSetForest.FoundDomains.$Domain['DomainEnterpriseAdministratorsTable'] = $DataSetForest.FoundDomains.$Domain.DomainEnterpriseAdministratorsRecursive | Sort-Object @{Expression='Enabled'; Descending=$true}, CanonicalName | Select-Object Name, @{Name='Username'; Expression={$_.'Sam Account Name'}}, Enabled, Protected, @{Name='LastLogonDate'; Expression={Get-Date $_.LastLogonDate -Format s}}, PasswordNeverExpires, PasswordNotRequired, BadLogonCount, @{Name='LastBadPasswordAttempt'; Expression={Get-Date $_.LastBadPasswordAttempt -Format s}}, @{Name='Created'; Expression={Get-Date $_.Created -Format s}}, @{Name='Modified'; Expression={Get-Date $_.Modified -Format s}}, @{Name='AccountExpirationDate'; Expression={Get-Date $_.AccountExpirationDate -Format s}}, CanonicalName
				$DataSetForest.FoundDomains.$Domain['SchemaAdminsTable'] = $DataSetForest.FoundDomains.$Domain.DomainGroupsMembersRecursive | Where-Object {$_.'Group SID' -eq ($DataSetForest.FoundDomains.$Domain.DomainInformation.DomainSID.Value + '-518')} | Sort-Object @{Expression='Enabled'; Descending=$true}, CanonicalName | Select-Object Name, @{Name='Username'; Expression={$_.'Sam Account Name'}}, Enabled, Protected, @{Name='LastLogonDate'; Expression={Get-Date $_.LastLogonDate -Format s}}, PasswordNeverExpires, PasswordNotRequired, BadLogonCount, @{Name='LastBadPasswordAttempt'; Expression={Get-Date $_.LastBadPasswordAttempt -Format s}}, @{Name='Created'; Expression={Get-Date $_.Created -Format s}}, @{Name='Modified'; Expression={Get-Date $_.Modified -Format s}}, @{Name='AccountExpirationDate'; Expression={Get-Date $_.AccountExpirationDate -Format s}}, CanonicalName
				foreach ($Stat in $AdminStats) {
					Panel -Invisible {
						Write-Information ("[INFO] Table $Domain $($Stat.Name)") -InformationAction Continue
						Table -DataTable $DataSetForest.FoundDomains.$Domain.($Stat.Table) -PreContent {'<div style="text-align:center;font-weight:bold">' + $Stat.Name + '</div>'} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
							TableButtonCSV
							TableButtonPageLength
							TableConditionalFormatting -Name 'Enabled' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
							TableConditionalFormatting -Name 'Protected' string eq -Value 'False' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
							TableConditionalFormatting -Name 'Protected' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
							TableConditionalFormatting -Name 'LastLogonDate' string eq -Value '' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
							TableConditionalFormatting -Name 'LastLogonDate' string lt -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
							TableConditionalFormatting -Name 'LastLogonDate' string ge -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGreen -BackgroundColor PaleGreen
							TableConditionalFormatting -Name 'PasswordNeverExpires' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
							TableConditionalFormatting -Name 'PasswordNeverExpires' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
							TableConditionalFormatting -Name 'PasswordNotRequired' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
							TableConditionalFormatting -Name 'PasswordNotRequired' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
							TableConditionalFormatting -Name 'BadLogonCount' number ge -Value ($DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Lockout Threshold') -Color DarkRed -BackgroundColor Pink
							TableConditionalFormatting -Name 'BadLogonCount' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
							TableConditionalFormatting -Name 'BadLogonCount' number eq -Value 0 -Color DarkGreen -BackgroundColor PaleGreen
							TableConditionalFormatting -Name 'LastBadPasswordAttempt' string gt -Value (Get-Date ($RunTime).AddMinutes(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Lockout Observation Window') -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
							TableConditionalFormatting -Name 'LastBadPasswordAttempt' string le -Value (Get-Date ($RunTime).AddMinutes(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Lockout Observation Window') -Format s) -Color DarkGreen -BackgroundColor PaleGreen
							TableConditionalFormatting -Name 'LastBadPasswordAttempt' string eq -Value '' -Color DarkGreen -BackgroundColor PaleGreen
							TableConditionalFormatting -Name 'AccountExpirationDate' string lt -Value (Get-Date ($RunTime) -Format s) -Color DarkRed -BackgroundColor Pink
							TableConditionalFormatting -Name 'AccountExpirationDate' string ge -Value (Get-Date ($RunTime) -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
							TableConditionalFormatting -Name 'AccountExpirationDate' string eq -Value '' -Color DarkGreen -BackgroundColor PaleGreen
							TableConditionalFormatting -Name 'Enabled' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink -Row
						}
					}
				}
			}
			Section -Name 'Users' -Collapsable {
				Panel -Invisible {
					$DataSetForest.FoundDomains.$Domain['DomainUsersTable'] = $DataSetForest.FoundDomains.$Domain.DomainUsers | Sort-Object @{Expression='Enabled'; Descending=$true}, CanonicalName | Select-Object Name, @{Name='Username'; Expression={$_.SamAccountName}}, Enabled, Protected, @{Name='Account Type'; Expression={
						switch -Wildcard ($_.CanonicalName) {
							'*Microsoft Exchange System Objects*' {'Exchange'; break}
							default {''}
						}}}, @{Name='LastLogonDate'; Expression={Get-Date $_.LastLogonDate -Format s}}, 'PasswordLastChanged(Days)', @{Name='PasswordExpiration'; Expression={Get-Date $_.DateExpiry -Format s}}, @{Name='PasswordLastSet'; Expression={Get-Date $_.PasswordLastSet -Format s}}, PasswordExpired, PasswordNeverExpires, PasswordNotRequired, BadLogonCount, @{Name='LastBadPasswordAttempt'; Expression={Get-Date $_.LastBadPasswordAttempt -Format s}}, @{Name='Created'; Expression={Get-Date $_.Created -Format s}}, @{Name='Modified'; Expression={Get-Date $_.Modified -Format s}}, @{Name='AccountExpirationDate'; Expression={Get-Date $_.AccountExpirationDate -Format s}}, CanonicalName
					Write-Information ("[INFO] Table $Domain DomainUsersTable") -InformationAction Continue
					Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainUsersTable -PostContent {
							'<div>
								<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE User rows are known system accounts.</span><br>
								<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED User rows are disabled accounts.</span><br>
								<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN User field means value is expected or to highlight field.</span><br>
								<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE User field means value may not be expected.</span><br>
								<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED User field means value is unexpected.</span><br>
							</div>'
						} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
						TableButtonCSV
						TableButtonPageLength
						TableConditionalFormatting -Name 'Account Type' string eq -Value 'Exchange' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod -Row
						TableConditionalFormatting -Name 'Enabled' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Protected' string eq -Value 'False' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'Protected' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'LastLogonDate' string eq -Value '' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'LastLogonDate' string lt -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'LastLogonDate' string ge -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordLastChanged(Days)' number gt -Value ($DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordLastChanged(Days)' number le -Value ($DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordExpiration' string eq -Value '' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordExpiration' string lt -Value (Get-Date ($RunTime) -Format s) -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordExpiration' string ge -Value (Get-Date ($RunTime) -Format s) -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordLastSet' string lt -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordLastSet' string ge -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordExpired' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordExpired' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordNeverExpires' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordNeverExpires' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordNotRequired' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordNotRequired' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'BadLogonCount' number ge -Value ($DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Lockout Threshold') -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'BadLogonCount' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'BadLogonCount' number eq -Value 0 -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'LastBadPasswordAttempt' string gt -Value (Get-Date ($RunTime).AddMinutes(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Lockout Observation Window') -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'LastBadPasswordAttempt' string le -Value (Get-Date ($RunTime).AddMinutes(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Lockout Observation Window') -Format s) -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'LastBadPasswordAttempt' string eq -Value '' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'AccountExpirationDate' string lt -Value (Get-Date ($RunTime) -Format s) -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'AccountExpirationDate' string ge -Value (Get-Date ($RunTime) -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'AccountExpirationDate' string eq -Value '' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Enabled' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink -Row
					}
				}
			}
			Section -Name 'Computers' -Collapsable {
				Panel -Invisible {
					$DataSetForest.FoundDomains.$Domain['DomainComputersTable'] = $DataSetForest.FoundDomains.$Domain.DomainComputers | Sort-Object @{Expression='Enabled'; Descending=$true}, CanonicalName | Select-Object Name, Enabled, Protected, OperatingSystem, OperatingSystemVersion, IPv4Address, IPv6Address, @{Name='LastLogonDate'; Expression={Get-Date $_.LastLogonDate -Format s}}, 'PasswordLastChanged(Days)', @{Name='PasswordLastSet'; Expression={Get-Date $_.PasswordLastSet -Format s}}, LockedOut, PasswordNeverExpires, PasswordNotRequired, @{Name='Created'; Expression={Get-Date $_.Created -Format s}}, @{Name='Modified'; Expression={Get-Date $_.Modified -Format s}}, CanonicalName
					Write-Information ("[INFO] Table $Domain DomainComputersTable") -InformationAction Continue
					Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainComputersTable -PostContent {
							'<div>
								<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Computer field means value is expected or to highlight field.</span><br>
								<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE Computer field means value may not be expected.</span><br>
								<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Computer field means value is unexpected.</span><br>
								<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Operating System means OS is on a supported version.</span><br>
								<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE Operating System means OS is on a version in extended support.</span><br>
								<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Operating System means OS is on an unsupported version.</span>
							</div>'
						} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
						TableButtonCSV
						TableButtonPageLength
						TableConditionalFormatting -Name 'Enabled' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Protected' string eq -Value 'False' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'Protected' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'OperatingSystem' string eq -Value 'Windows 2000 Professional' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows 7' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows 8' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows 8.1' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows Vista' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows XP' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '5.0 (2195)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '5.1 (2600)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.0 (6000)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.0 (6001)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.0 (6002)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.1 (7600)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.1 (7601)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.2 (8250)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.2 (9200)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.3 (9600)' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (10240)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (10586)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (14393)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (15063)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (16299)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (17134)' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (17763)' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (18362)' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'LastLogonDate' string eq -Value '' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'LastLogonDate' string lt -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'LastLogonDate' string ge -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordLastChanged(Days)' number gt -Value ($DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordLastChanged(Days)' number le -Value ($DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordLastSet' string lt -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordLastSet' string ge -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'LockedOut' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'LockedOut' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordNeverExpires' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordNeverExpires' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordNotRequired' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordNotRequired' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Enabled' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink -Row
					}
				}
			}
			Section -Name 'Servers' -Collapsable {
				Panel -Invisible {
					$DataSetForest.FoundDomains.$Domain['DomainServersTable'] = $DataSetForest.FoundDomains.$Domain.DomainServers | Sort-Object @{Expression='Enabled'; Descending=$true}, CanonicalName | Select-Object Name, Enabled, Protected, OperatingSystem, OperatingSystemVersion, IPv4Address, IPv6Address, @{Name='LastLogonDate'; Expression={Get-Date $_.LastLogonDate -Format s}}, 'PasswordLastChanged(Days)', @{Name='PasswordLastSet'; Expression={Get-Date $_.PasswordLastSet -Format s}}, LockedOut, PasswordNeverExpires, PasswordNotRequired, @{Name='Created'; Expression={Get-Date $_.Created -Format s}}, @{Name='Modified'; Expression={Get-Date $_.Modified -Format s}}, CanonicalName
					Write-Information ("[INFO] Table $Domain DomainServersTable") -InformationAction Continue
					Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainServersTable -PostContent {
							'<div>
								<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Server field means value is expected or to highlight field.</span><br>
								<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE Server field means value may not be expected.</span><br>
								<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Server field means value is unexpected.</span><br>
								<span style="color: rgb(0, 100, 0); background-color: rgb(152, 251, 152);">GREEN Operating System means OS is on a supported version.</span><br>
								<span style="color: rgb(184, 134, 11); background-color: rgb(238, 232, 170);">ORANGE Operating System means OS is on a version in extended support.</span><br>
								<span style="color: rgb(139, 0, 0); background-color: rgb(255, 192, 203);">RED Operating System means OS is on an unsupported version.</span>
							</div>'
						} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
						TableButtonCSV
						TableButtonPageLength
						TableConditionalFormatting -Name 'Enabled' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Protected' string eq -Value 'False' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'Protected' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows Server 2000' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows Server 2003' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows Server 2008' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows Server 2012' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows Server 2012 R2' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows Server 2016' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'OperatingSystem' string ge -Value 'Windows Server 2019' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '5.0 (2195)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '5.2 (3790)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.0 (6001)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.0 (6002)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.0 (6003)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.1 (7600)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.1 (7601)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.2 (9200)' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '6.3 (9600)' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (10240)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (10586)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (14393)' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (15063)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (16299)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (17134)' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (17763)' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'OperatingSystemVersion' string eq -Value '10.0 (18362)' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'LastLogonDate' string eq -Value '' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'LastLogonDate' string lt -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'LastLogonDate' string ge -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordLastChanged(Days)' number gt -Value ($DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordLastChanged(Days)' number le -Value ($DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordLastSet' string lt -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordLastSet' string ge -Value (Get-Date ($RunTime).AddDays(-$DataSetForest.FoundDomains.$Global:Domain.DomainDefaultPasswordPolicy.'Max Password Age') -Format s) -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'LockedOut' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'LockedOut' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordNeverExpires' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordNeverExpires' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'PasswordNotRequired' string eq -Value 'True' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'PasswordNotRequired' string eq -Value 'False' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Enabled' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink -Row
					}
				}
			}
			$Count = 0
			foreach ($LAPS in $DataSetForest.FoundDomains.$Domain.DomainLAPS) {if ($LAPS.LapsPassword -ne '') {$Count++}}
			if ($DataSetForest.FoundDomains.$Domain.DomainBitLocker.Count -gt 0 -and $Count -gt 0) {
				Section -Name 'Device Security' -Collapsable {
					if ($DataSetForest.FoundDomains.$Domain.DomainBitLocker.Count -gt 0) {
						Panel -Invisible {
							Write-Information ("[INFO] Table $Domain DomainBitLocker") -InformationAction Continue
							Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainBitLocker -PreContent {'<div style="text-align:center;font-weight:bold">BitLocker</div>'} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
								TableButtonCSV
								TableButtonPageLength
								TableConditionalFormatting -Name 'Enabled' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen -Row
							}
						}
					}
					if ($Count -gt 0) {
						Panel -Invisible {
							$DataSetForest.FoundDomains.$Domain['DomainLAPSTable'] = $DataSetForest.FoundDomains.$Domain.DomainLAPS | Sort-Object @{Expression='LapsExpire(days)'; Descending=$true} | Select-Object Name, 'Operating System', LapsPassword, 'LapsExpire(days)', @{Name='LapsExpirationTime'; Expression={Get-Date $_.LapsExpirationTime -Format s}}, DistinguishedName
							Write-Information ("[INFO] Table $Domain DomainLAPSTable") -InformationAction Continue
							Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainLAPSTable -PreContent {'<div style="text-align:center;font-weight:bold">LAPS</div>'} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
								TableButtonCSV
								TableButtonPageLength
								TableConditionalFormatting -Name 'LapsExpire(days)' number le -Value 0 -Color DarkRed -BackgroundColor Pink -Row
							}
						}
					}
				}
			}
			Section -Name 'Groups' -Collapsable {
				Panel -Invisible {
					$DataSetForest.FoundDomains.$Domain['DomainGroupsTable'] = $DataSetForest.FoundDomains.$Domain.DomainGroups | Sort-Object 'Group SID' | Select-Object 'Group Name', 'Group Category', 'Group Scope', 'High Privileged Group', 'Member Count', 'MemberOf Count', Domain
					Write-Information ("[INFO] Table $Domain DomainGroupsTable") -InformationAction Continue
					Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainGroupsTable -PreContent {'<div style="text-align:center;font-weight:bold">Domain Groups</div>'} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
						TableButtonCSV
						TableButtonPageLength
						TableConditionalFormatting -Name 'Member Count' number eq -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'MemberOf Count' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'High Privileged Group' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
					}
				}
				Panel -Invisible {
					$DataSetForest.FoundDomains.$Domain['DomainGroupsPriviligedTable'] = $DataSetForest.FoundDomains.$Domain.DomainGroupsPriviliged | Sort-Object 'Group SID' | Select-Object 'Group Name', 'Group Category', 'Group Scope', 'High Privileged Group', 'Member Count', 'MemberOf Count', Domain
					Write-Information ("[INFO] Table $Domain DomainGroupsPriviligedTable") -InformationAction Continue
					Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainGroupsPriviligedTable -PreContent {'<div style="text-align:center;font-weight:bold">Privileged Groups</div>'} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
						TableButtonCSV
						TableButtonPageLength
						TableConditionalFormatting -Name 'Member Count' number eq -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'MemberOf Count' number gt -Value 0 -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'High Privileged Group' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
					}
				}
			}
			Section -Name 'Organizational Units' -Collapsable {
				Panel -Invisible {
					$DataSetForest.FoundDomains.$Domain['DomainOrganizationalUnitsTable'] = $DataSetForest.FoundDomains.$Domain.DomainOrganizationalUnits | Sort-Object DistinguishedName | Select-Object 'Canonical Name', Protected, Description, @{Name='Created'; Expression={Get-Date $_.Created -Format s}}, @{Name='Modified'; Expression={Get-Date $_.Modified -Format s}}, @{Name='Deleted'; Expression={Get-Date $_.Deleted -Format s}}
					Write-Information ("[INFO] Table $Domain DomainOrganizationalUnitsTable") -InformationAction Continue
					Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainOrganizationalUnitsTable -PreContent {'<div style="text-align:center;font-weight:bold">Organizational Units</div>'} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
						TableButtonCSV
						TableButtonPageLength
						TableConditionalFormatting -Name 'Protected' string eq -Value 'False' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
						TableConditionalFormatting -Name 'Protected' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
					}
				}
				Panel -Invisible {
					$DataSetForest.FoundDomains.$Domain['DomainOrganizationalUnitsBasicACLTable'] = $DataSetForest.FoundDomains.$Domain.DomainOrganizationalUnitsBasicACL | Sort-Object 'Distinguished Name' | Select-Object -ExcludeProperty Type
					Write-Information ("[INFO] Table $Domain DomainOrganizationalUnitsBasicACLTable") -InformationAction Continue
					Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainOrganizationalUnitsBasicACLTable -PreContent {'<div style="text-align:center;font-weight:bold">OU ACLs</div>'} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
						TableButtonCSV
						TableButtonPageLength
						TableConditionalFormatting -Name 'Are AccessRules Protected' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Are AccessRules Protected' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
						TableConditionalFormatting -Name 'Are AuditRules Protected' string eq -Value 'False' -Color DarkRed -BackgroundColor Pink
						TableConditionalFormatting -Name 'Are AuditRules Protected' string eq -Value 'True' -Color DarkGreen -BackgroundColor PaleGreen
					}
				}
				if ($DataSetForest.FoundDomains.$Domain.DomainOrganizationalUnitsExtended.Count -gt 0) {
					Panel -Invisible {
						Write-Information ("[INFO] Table $Domain DomainOrganizationalUnitsExtended") -InformationAction Continue
						Table -DataTable $DataSetForest.FoundDomains.$Domain.DomainOrganizationalUnitsExtended -PreContent {'<div style="text-align:center;font-weight:bold">OU ACLs Extended</div>'} -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
							TableButtonCSV
							TableButtonPageLength
						}
					}
				}
			}
		}
	}
	Tab -Name 'Changes in Last 60 days' -IconSolid calendar {
		Section -Name 'User Events' -Collapsable {
			Panel -Invisible {
				$DataSetEvents["ADUser"] = @()
				foreach ($Event in $DataSetEvents.ADUserChanges) {
					$DataSetEvents.ADUser += [PSCustomObject]@{
						'Domain Controller'=$Event.'Domain Controller';
						'User Affected'=$Event.'User Affected';
						Action=$Event.Action;
						'Computer Lockout On'=$null;
						'Old Uac Value'=$Event.'Old Uac Value';
						'New Uac Value'=$Event.'New Uac Value';
						'User Account Control'=$Event.'User Account Control';
						Who=$Event.Who;
						When=Get-Date $Event.When -Format s;
						'Event ID'=$Event.'Event ID'
					}
				}
				foreach ($Event in $DataSetEvents.ADUserStatus) {
					$DataSetEvents.ADUser += [PSCustomObject]@{
						'Domain Controller'=$Event.'Domain Controller';
						'User Affected'=$Event.'User Affected';
						Action=$Event.Action;
						'Computer Lockout On'=$null;
						'Old Uac Value'=$null;
						'New Uac Value'=$null;
						'User Account Control'=$null;
						Who=$Event.Who;
						When=Get-Date $Event.When -Format s;
						'Event ID'=$Event.'Event ID'
					}
				}
				foreach ($Event in $DataSetEvents.ADUserLockouts) {
					$DataSetEvents.ADUser += [PSCustomObject]@{
						'Domain Controller'=$Event.'Domain Controller';
						'User Affected'=$Event.'User Affected';
						Action=$Event.Action;
						'Computer Lockout On'=$Event.'Computer Lockout On';
						'Old Uac Value'=$null;
						'New Uac Value'=$null;
						'User Account Control'=$null;
						Who=$Event.'Reported By';
						When=Get-Date $Event.When -Format s;
						'Event ID'=$Event.'Event ID'
					}
				}
				$DataSetEvents["ADUserTable"] = $DataSetEvents.ADUser | Sort-Object 'Domain Controller', @{Expression={Get-Date $_.When -Format s}; Descending=$true}
				Write-Information ("[INFO] Table ADUserTable") -InformationAction Continue
				Table -DataTable $DataSetEvents.ADUserTable -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					TableConditionalFormatting -Name 'Action' string eq -Value 'A user account was locked out.' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action' string eq -Value 'A user account was deleted.' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action' string eq -Value 'A user account was disabled.' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action' string ge -Value 'An attempt was made to change an account' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Action' string ge -Value 'An attempt was made to reset an account' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Action' string eq -Value 'A user account was changed.' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Action' string eq -Value 'A user account was unlocked.' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'Action' string eq -Value 'A user account was enabled.' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'Action' string eq -Value 'A user account was created.' -Color DarkGreen -BackgroundColor PaleGreen
				}
			}
		}
		Section -Name 'Computer Events' -Collapsable {
			Panel -Invisible {
				$DataSetEvents["ADComputer"] = @()
				foreach ($Event in $DataSetEvents.ADComputerCreatedChanged) {
					$DataSetEvents.ADComputer += [PSCustomObject]@{
						'Domain Controller'=$Event.'Domain Controller';
						'Computer Affected'=$Event.'Computer Affected';
						Action=$Event.Action;
						'User Parameters'=$Event.'User Parameters';
						'Old Uac Value'=$Event.'Old Uac Value';
						'New Uac Value'=$Event.'New Uac Value';
						'User Account Control'=$Event.'User Account Control';
						Who=$Event.Who;
						When=Get-Date $Event.When -Format s;
						'Event ID'=$Event.'Event ID'
					}
				}
				foreach ($Event in $DataSetEvents.ADComputerDeleted) {
					$DataSetEvents.ADComputer += [PSCustomObject]@{
						'Domain Controller'=$Event.'Domain Controller';
						'Computer Affected'=$Event.'Computer Affected';
						Action=$Event.Action;
						'User Parameters'=$null;
						'Old Uac Value'=$null;
						'New Uac Value'=$null;
						'User Account Control'=$null;
						Who=$Event.Who;
						When=Get-Date $Event.When -Format s;
						'Event ID'=$Event.'Event ID'
					}
				}
				$DataSetEvents["ADComputerTable"] = $DataSetEvents.ADComputer | Sort-Object 'Domain Controller', @{Expression={Get-Date $_.When -Format s}; Descending=$true}
				Write-Information ("[INFO] Table ADComputerTable") -InformationAction Continue
				Table -DataTable $DataSetEvents.ADComputerTable -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					TableConditionalFormatting -Name 'Action' string eq -Value 'A computer account was deleted.' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action' string eq -Value 'A computer account was changed.' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Action' string eq -Value 'A computer account was created.' -Color DarkGreen -BackgroundColor PaleGreen
				}
			}
		}
		Section -Name 'Group Events' -Collapsable {
			Panel -Invisible {
				$DataSetEvents["ADGroup"] = @()
				foreach ($Event in $DataSetEvents.ADGroupChanges) {
					$DataSetEvents.ADGroup += [PSCustomObject]@{
						'Domain Controller'=$Event.'Domain Controller';
						'Group Name'=$Event.'Group Name';
						Action=$Event.Action;
						'Member Name'=$null;
						'Changed Group Type'=$Event.'Changed Group Type';
						'Changed SamAccountName'=$Event.'Changed SamAccountName';
						'Changed SidHistory'=$Event.'Changed SidHistory';
						Who=$Event.Who;
						When=Get-Date $Event.When -Format s;
						'Event ID'=$Event.'Event ID'
					}
				}
				foreach ($Event in $DataSetEvents.ADGroupCreateDelete) {
					$DataSetEvents.ADGroup += [PSCustomObject]@{
						'Domain Controller'=$Event.'Domain Controller';
						'Group Name'=$Event.'Group Name';
						Action=$Event.Action;
						'Member Name'=$null;
						'Changed Group Type'=$null;
						'Changed SamAccountName'=$Gnull;
						'Changed SidHistory'=$null;
						Who=$Event.Who;
						When=Get-Date $Event.When -Format s;
						'Event ID'=$Event.'Event ID'
					}
				}
				foreach ($Event in $DataSetEvents.ADGroupMembershipChanges) {
					$DataSetEvents.ADGroup += [PSCustomObject]@{
						'Domain Controller'=$Event.'Domain Controller';
						'Group Name'=$Event.'Group Name';
						Action=$Event.Action;
						'Member Name'=$Event.'Member Name';
						'Changed Group Type'=$null;
						'Changed SamAccountName'=$null;
						'Changed SidHistory'=$null;
						Who=$Event.Who;
						When=Get-Date $Event.When -Format s;
						'Event ID'=$Event.'Event ID'
					}
				}
				$DataSetEvents["ADGroupTable"] = $DataSetEvents.ADGroup | Sort-Object 'Domain Controller', @{Expression={Get-Date $_.When -Format s}; Descending=$true}
				Write-Information ("[INFO] Table ADGroupTable") -InformationAction Continue
				Table -DataTable $DataSetEvents.ADGroupTable -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					TableConditionalFormatting -Name 'Action' string eq -Value 'A security-enabled global group was deleted.' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action' string eq -Value 'A security-enabled universal group was deleted.' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action' string eq -Value 'A member was removed from a security-enabled global group.' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action' string eq -Value 'A member was removed from a security-enabled universal group.' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action' string eq -Value 'A member was added to a security-enabled global group.' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'Action' string eq -Value 'A member was added to a security-enabled universal group.' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'Action' string eq -Value 'A security-enabled global group was changed.' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Action' string eq -Value 'A security-enabled universal group was changed.' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Action' string eq -Value 'A security-enabled global group was created.' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'Action' string eq -Value 'A security-enabled universal group was created.' -Color DarkGreen -BackgroundColor PaleGreen
				}
			}
		}
		Section -Name 'Organizational Unit Events' -Collapsable {
			Panel -Invisible {
				$DataSetEvents["ADOrganizationalUnitChangesDetailedTable"] = $DataSetEvents.ADOrganizationalUnitChangesDetailed | Sort-Object 'Domain Controller', @{Expression={Get-Date $_.When -Format s}; Descending=$true} | Select-Object 'Domain Controller', 'Organizational Unit', Action, 'Action Detail', 'Field Changed', 'Field Value', Who, @{Name='When'; Expression={Get-Date $_.When -Format s}}, 'Event ID'
				Write-Information ("[INFO] Table ADOrganizationalUnitChangesDetailedTable") -InformationAction Continue
				Table -DataTable $DataSetEvents.ADOrganizationalUnitChangesDetailedTable -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					TableConditionalFormatting -Name 'Action' string eq -Value 'A directory service object was deleted.' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action' string eq -Value 'A directory service object was modified.' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Action' string eq -Value 'A directory service object was created.' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'Action Detail' string eq -Value 'Value Deleted' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action Detail' string eq -Value 'Value Modified' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Action Detail' string eq -Value 'Value Added' -Color DarkGreen -BackgroundColor PaleGreen
				}
			}
		}
		Section -Name 'Group Policy Events' -Collapsable {
			Panel -Invisible {
				$DataSetEvents["ADGroupPolicyChangesTable"] = $DataSetEvents.ADGroupPolicyChanges | Sort-Object 'Domain Controller', @{Expression={Get-Date $_.When -Format s}; Descending=$true} | Select-Object 'Domain Controller', ObjectDN, ObjectGUID, ObjectClass, Action, @{Name='Action Detail'; Expression={$_.OperationType}}, OperationCorelationID, OperationApplicationCorrelationID, Who, @{Name='When'; Expression={Get-Date $_.When -Format s}}, 'Event ID'
				Write-Information ("[INFO] Table ADGroupPolicyChangesTable") -InformationAction Continue
				Table -DataTable $DataSetEvents.ADGroupPolicyChangesTable -Buttons @() -PagingOptions @(10, 20, 30) -DisableStateSave -HideFooter -Verbose {
					TableButtonCSV
					TableButtonPageLength
					TableConditionalFormatting -Name 'Action' string eq -Value 'A directory service object was deleted.' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action' string eq -Value 'A directory service object was modified.' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Action' string eq -Value 'A directory service object was created.' -Color DarkGreen -BackgroundColor PaleGreen
					TableConditionalFormatting -Name 'Action Detail' string eq -Value 'Value Deleted' -Color DarkRed -BackgroundColor Pink
					TableConditionalFormatting -Name 'Action Detail' string eq -Value 'Value Modified' -Color DarkGoldenrod -BackgroundColor PaleGoldenrod
					TableConditionalFormatting -Name 'Action Detail' string eq -Value 'Value Added' -Color DarkGreen -BackgroundColor PaleGreen
				}
			}
		}
	}
}
Write-Information ("[INFO] Generating DCDiag Text File") -InformationAction Continue
dcdiag /e > $SaveLocation\DCDiag_$((Get-ADForest).Name)_$(Get-Date $ReportTime -Format yyyy-MM-ddTHH-mm-ss).txt
Write-Information ("[INFO] Generating RepAdmin Text File") -InformationAction Continue
repadmin /replsummary > $SaveLocation\RepAdmin_$((Get-ADForest).Name)_$(Get-Date $ReportTime -Format yyyy-MM-ddTHH-mm-ss).txt
