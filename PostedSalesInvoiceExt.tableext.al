pageextension 50100 SD_PostedSalesInvExt extends "Posted Sales Invoice"
{
    actions
    {
        addafter(Email)
        {
            action(OpenInOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open in OneDrive';
                Image = Cloud;
                Enabled = ShareOptionsEnabled;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Category6;
                PromotedIsBig = true;
                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    DocumentServiceManagement: Codeunit "Document Service Management";
                    InStr: InStream;
                begin
                    GetInvoicePDF(TempBlob);
                    TempBlob.CreateInStream(InStr);
                    DocumentServiceManagement.OpenInOneDrive(StrSubstNo(SalesInvoiceName, Rec."No."), '.pdf', InStr);

                    //For attachments:
                    //DocumentServiceManagement.OpenInOneDriveFromMedia(SalesInvoiceName,'.pdf',"Document Reference ID".MediaId());
                end;
            }

            action(BlobStorageDemo)
            {
                ApplicationArea = All;
                Caption = 'Blob Storage Demo';
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Category6;
                PromotedIsBig = true;
                Image = FiledOverview;

                trigger OnAction()
                var
                    BlobStorageMgt: Codeunit BlobStorageManagement;
                begin
                    BlobStorageMgt.Run()
                end;
            }
        }
    }
    var
        ShareOptionsEnabled: Boolean;
        SalesInvoiceName: Label 'Sales Invoice %1';

    trigger OnOpenPage()
    var
        DocumentSharing: Codeunit "Document Sharing";
    begin
        ShareOptionsEnabled := DocumentSharing.ShareEnabled();
    end;

    local procedure GetInvoicePDF(var TempBlob: Codeunit "Temp Blob")
    var
        ReportSelections: Record "Report Selections";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        RecRef.SetRecFilter();
        ReportSelections.GetPdfReportForCust(TempBlob, ReportSelections.Usage::"S.Invoice", RecRef, Rec.GetSellToCustomerFaxNo());
    end;
}