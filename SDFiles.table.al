table 50100 "SD Files"
{
    DataClassification = CustomerContent;
    
    fields
    {
        field(1;ID; Guid)
        {
            DataClassification = CustomerContent;            
        }
        field(2; Content; Blob)
        {
            DataClassification = SystemMetadata;
        }
        field(3; BlobID; BigInteger)
        {
            DataClassification = SystemMetadata;
        }
    }
    
    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }
}