configuration SampleIISInstall
{
    node ("localhost")
    {
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name = "Web-Server"
        }
    }
}

# Compile the configuration file to a MOF format
SampleIISInstall