multibranchPipelineJob('perimeterx-nginx-plugin-docker') {
    branchSources {
        github {
            scanCredentialsId('github-albertpx-token')
            repoOwner('PerimeterX')
            repository('perimeterx-nginx-plugin')
        }
    }
    orphanedItemStrategy {
        discardOldItems {
            numToKeep(20)
            daysToKeep(20)
        }
    }
    factory {
        workflowBranchProjectFactory {
            scriptPath('jenkins/jenkinsfile/Jenkinsfile')
        }
    }
    triggers {
        periodic(2)
    }
    configure {
        it / 'sources' / 'data' / 'jenkins.branch.BranchSource' / 'source' << 'traits' {
            'org.jenkinsci.plugins.github__branch__source.BranchDiscoveryTrait' {
                'strategyId'('1')
            }
            'org.jenkinsci.plugins.github__branch__source.OriginPullRequestDiscoveryTrait' {
                'strategyId'('2')
            }
            'jenkins.scm.impl.trait.WildcardSCMHeadFilterTrait' {
                'includes'('master dev PR-*')
                'excludes'('')
            }
            'jenkins.plugins.git.traits.PruneStaleBranchTrait' {
                'extension'(class: 'hudson.plugins.git.extensions.impl.PruneStaleBranch')
            }
        }
    }
}