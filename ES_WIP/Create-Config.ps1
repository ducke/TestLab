Configuration TestES
{

    Import-DscResource -Module ce_ElasticSearch

    node localhost
    {
        ce_ElasticSearchConfig JustAConfig
        {
            ConfigFilePath = "C:\dev\TestLab\Roles\elasticsearch\elasticsearch.yml"
            Config = @{
                "cluster.name" = "HAndFrans"
                "ein.foo" = "bar"
            }
            Ensure = "Present"
        }
    }
}