import Foundation
import SwiftUI
import PDFKit
import StoreKit

class ExportService {
    static let shared = ExportService()
    
    // MARK: - Text Sharing
    func generateTextSummary(viewModel: CalculatorViewModel) -> String {
        guard let result = viewModel.result else { return "" }
        
        var summary = "--- \(viewModel.calculatorType.localizedName) \(L10n.analysis) ---\n"
        summary += "\(Date().formatted(date: .long, time: .shortened))\n\n"
        
        summary += "\(L10n.loanSummary):\n"
        summary += "- \(primaryAmountLabel(for: viewModel)): \(CurrencyFormatter.format(amount: primaryAmountValue(for: viewModel), country: viewModel.selectedCountry))\n"
        summary += "- \(L10n.interestRate): \(String(format: "%.2f%%", viewModel.interestRate))\n"
        summary += "- \(L10n.loanTerm): \(viewModel.loanTermYears) \(L10n.years)\n"
        
        if viewModel.downPayment > 0 {
            summary += "- \(L10n.downPayment): \(CurrencyFormatter.format(amount: viewModel.downPayment, country: viewModel.selectedCountry))\n"
        }
        
        // Calculator-Specific Details
        summary += extraDetailsText(for: viewModel)
        
        summary += "\n\(L10n.paymentBreakdown):\n"
        summary += "- \(L10n.monthlyPayment): \(CurrencyFormatter.format(amount: result.monthlyPayment, country: viewModel.selectedCountry))\n"
        summary += "- \(L10n.totalInterest): \(CurrencyFormatter.format(amount: result.totalInterest, country: viewModel.selectedCountry))\n"
        summary += "- \(L10n.totalPayment): \(CurrencyFormatter.format(amount: result.totalPayment, country: viewModel.selectedCountry))\n"
        summary += "- \(L10n.payoffDate): \(result.payoffDate.formatted(date: .abbreviated, time: .omitted))\n"
        
        if viewModel.extraMonthlyPayment > 0 {
            summary += "\n\(L10n.extraPayment) (\(CurrencyFormatter.format(amount: viewModel.extraMonthlyPayment, country: viewModel.selectedCountry))):\n"
            summary += "- \(L10n.interestSaved): \(CurrencyFormatter.format(amount: viewModel.interestSaved, country: viewModel.selectedCountry))\n"
            let years = viewModel.monthsSaved / 12
            let months = viewModel.monthsSaved % 12
            summary += "- \(L10n.timeSaved): \(years > 0 ? "\(years)y \(months)m" : "\(months)m")\n"
        }
        
        summary += "\n\(L10n.string("generated_by")) LoanPro 2025"
        return summary
    }
    
    // MARK: - Helper Functions
    private func primaryAmountLabel(for viewModel: CalculatorViewModel) -> String {
        switch viewModel.calculatorType {
        case .home, .fha, .stampDuty: return L10n.propertyValue
        case .auto, .rv: return L10n.loanAmount
        case .student: return L10n.loanAmount
        case .eligibility: return L10n.annualIncome
        case .reverse: return L10n.monthlyBudget
        default: return L10n.loanAmount
        }
    }
    
    private func primaryAmountValue(for viewModel: CalculatorViewModel) -> Double {
        switch viewModel.calculatorType {
        case .home, .fha, .stampDuty: return viewModel.propertyValue
        case .eligibility: return viewModel.annualIncome
        case .reverse: return viewModel.monthlyBudget
        default: return viewModel.loanAmount
        }
    }
    
    private func extraDetailsText(for viewModel: CalculatorViewModel) -> String {
        var details = ""
        
        switch viewModel.calculatorType {
        case .auto, .rv:
            if viewModel.tradeInValue > 0 {
                details += "- \(L10n.tradeInValue): \(CurrencyFormatter.format(amount: viewModel.tradeInValue, country: viewModel.selectedCountry))\n"
            }
            if viewModel.salesTaxRate > 0 {
                details += "- \(L10n.salesTax): \(String(format: "%.2f%%", viewModel.salesTaxRate))\n"
            }
            if viewModel.registrationFees > 0 {
                details += "- \(L10n.registrationFees): \(CurrencyFormatter.format(amount: viewModel.registrationFees, country: viewModel.selectedCountry))\n"
            }
            
        case .home, .fha:
            if viewModel.propertyTax > 0 {
                details += "- \(L10n.propertyTax): \(CurrencyFormatter.format(amount: viewModel.propertyTax, country: viewModel.selectedCountry))\(L10n.string("per_month"))\n"
            }
            if viewModel.homeInsurance > 0 {
                details += "- \(L10n.homeInsurance): \(CurrencyFormatter.format(amount: viewModel.homeInsurance, country: viewModel.selectedCountry))\(L10n.string("per_month"))\n"
            }
            if viewModel.hoaFees > 0 {
                details += "- \(L10n.hoaFees): \(CurrencyFormatter.format(amount: viewModel.hoaFees, country: viewModel.selectedCountry))\(L10n.string("per_month"))\n"
            }
            
        case .student:
            if viewModel.gracePeriodMonths > 0 {
                details += "- \(L10n.gracePeriod): \(viewModel.gracePeriodMonths) \(L10n.string("months_short"))\n"
            }
            
        case .eligibility:
            details += "\n\(L10n.string("eligibility_analysis")):\n"
            details += "- \(L10n.string("monthly_income")): \(CurrencyFormatter.format(amount: viewModel.grossMonthlyIncome, country: viewModel.selectedCountry))\n"
            details += "- \(L10n.monthlyDebts): \(CurrencyFormatter.format(amount: viewModel.monthlyDebts, country: viewModel.selectedCountry))\n"
            details += "- \(L10n.string("max_affordable_emi")): \(CurrencyFormatter.format(amount: viewModel.maxMonthlyEMI, country: viewModel.selectedCountry))\n"
            details += "- \(L10n.borrowingPower): \(CurrencyFormatter.format(amount: viewModel.affordableLoanAmount, country: viewModel.selectedCountry))\n"
            
        default:
            break
        }
        
        return details
    }
    
    private func extraDetailsCSV(for viewModel: CalculatorViewModel) -> String {
        var details = ""
        
        switch viewModel.calculatorType {
        case .auto, .rv:
            if viewModel.tradeInValue > 0 {
                details += "\(L10n.tradeInValue),\(viewModel.tradeInValue)\n"
            }
            if viewModel.salesTaxRate > 0 {
                details += "\(L10n.salesTax),\(viewModel.salesTaxRate)%\n"
            }
            if viewModel.registrationFees > 0 {
                details += "\(L10n.registrationFees),\(viewModel.registrationFees)\n"
            }
            
        case .home, .fha:
            if viewModel.propertyTax > 0 {
                details += "\(L10n.string("property_tax_monthly")),\(viewModel.propertyTax)\n"
            }
            if viewModel.homeInsurance > 0 {
                details += "\(L10n.string("home_insurance_monthly")),\(viewModel.homeInsurance)\n"
            }
            if viewModel.hoaFees > 0 {
                details += "\(L10n.string("hoa_fees_monthly")),\(viewModel.hoaFees)\n"
            }
            
        case .student:
            if viewModel.gracePeriodMonths > 0 {
                details += "\(L10n.gracePeriod),\(viewModel.gracePeriodMonths) \(L10n.string("months_short"))\n"
            }
            
        case .eligibility:
            details += "\(L10n.string("monthly_income")),\(viewModel.grossMonthlyIncome)\n"
            details += "\(L10n.monthlyDebts),\(viewModel.monthlyDebts)\n"
            details += "\(L10n.string("max_affordable_emi")),\(viewModel.maxMonthlyEMI)\n"
            details += "\(L10n.borrowingPower),\(viewModel.affordableLoanAmount)\n"
            
        default:
            break
        }
        
        return details
    }
    
    // MARK: - Helpers
    private func getExportDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let exportDir = paths[0].appendingPathComponent("Exports")
        if !FileManager.default.fileExists(atPath: exportDir.path) {
            try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        }
        return exportDir
    }

    // MARK: - CSV Export
    func generateCSV(for viewModel: CalculatorViewModel, includeSummary: Bool) -> URL? {
        guard let result = viewModel.result else { return nil }
        
        var csvString = "App Name,LoanPro 2025\n"
        csvString += "\(L10n.string("report")),\(L10n.string("loan_analysis_report"))\n\n"
        
        if includeSummary {
            csvString += "\(L10n.string("loan_analysis_report"))\n"
            csvString += "\(L10n.string("type")),\(viewModel.calculatorType.rawValue)\n"
            csvString += "\(L10n.string("date")),\(Date().formatted(date: .numeric, time: .omitted))\n"
            csvString += "\(primaryAmountLabel(for: viewModel)),\(primaryAmountValue(for: viewModel))\n"
            csvString += "\(L10n.string("rate")),\(viewModel.interestRate)%\n"
            csvString += "\(L10n.string("term")),\(viewModel.loanTermYears) \(L10n.string("years_short"))\n"
            
            if viewModel.downPayment > 0 {
                csvString += "\(L10n.downPayment),\(viewModel.downPayment)\n"
            }
            
            // Calculator-specific details
            csvString += extraDetailsCSV(for: viewModel)
            
            csvString += "\(L10n.monthlyPayment),\(result.monthlyPayment)\n"
            csvString += "\(L10n.totalInterest),\(result.totalInterest)\n"
            csvString += "\(L10n.totalPayment),\(result.totalPayment)\n\n"
        }
        
        // Amortization Header
        csvString += "\(L10n.month),\(L10n.principal),\(L10n.interest),\(L10n.string("tax")),\(L10n.balance),\(L10n.totalPayment)\n"
        
        for entry in result.amortizationSchedule {
            csvString += "\(entry.month),\(String(format: "%.2f", entry.principal)),\(String(format: "%.2f", entry.interest)),\(String(format: "%.2f", entry.tax)),\(String(format: "%.2f", entry.balance)),\(String(format: "%.2f", entry.totalPayment))\n"
        }
        
        csvString += "\n\(L10n.string("generated_by")),LoanPro 2025\n"
        
        let fileName = includeSummary ? "Loan_Full_Report.csv" : "Amortization_Schedule.csv"
        let path = getExportDirectory().appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Failed to create CSV: \(error)")
            return nil
        }
    }
    
    // MARK: - PDF Export
    @MainActor
    func generatePDF(for viewModel: CalculatorViewModel, includeSchedule: Bool) -> URL? {
        guard let result = viewModel.result else { return nil }
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // standard US Letter
        let fileName = includeSchedule ? "Loan_Full_Report.pdf" : "Amortization_Schedule.pdf"
        let path = getExportDirectory().appendingPathComponent(fileName)
        
        do {
            try pdfRenderer.writePDF(to: path) { context in
                context.beginPage()
                
                // Get PDF customization settings
                let settings = SettingsManager.shared
                let shouldRemoveWatermark = settings.removePDFWatermark
                let shouldAddCustomName = settings.addCustomNameToPDF
                let customName = settings.customPDFName
                
                // Draw Logo Placeholder (skip if watermark removal is enabled)
                if !shouldRemoveWatermark {
                    let logoRect = CGRect(x: 50, y: 40, width: 40, height: 40)
                    let path = UIBezierPath(roundedRect: logoRect, cornerRadius: 10)
                    UIColor.systemIndigo.setFill()
                    path.fill()
                    
                    // Draw Icon Placeholder inside logo
                    let iconSymbol = UIImage(systemName: "percent.circle.fill")?.withTintColor(.white)
                    iconSymbol?.draw(in: logoRect.insetBy(dx: 8, dy: 8))
                }
                
                // Draw App Name or Custom Name
                let nameToDisplay = shouldAddCustomName && !customName.isEmpty ? customName : "LoanPro 2025"
                let nameAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 20),
                    .foregroundColor: shouldRemoveWatermark ? UIColor.clear : UIColor.systemIndigo
                ]
                // Only draw name if not removing watermark, or if adding custom name (even if watermark removal is on)
                if !shouldRemoveWatermark || shouldAddCustomName {
                    nameToDisplay.draw(at: CGPoint(x: 100, y: 48), withAttributes: nameAttributes)
                }
                
                let title = L10n.string("loan_analysis_report")
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24)
                ]
                title.draw(at: CGPoint(x: 50, y: 100), withAttributes: attributes)
                
                var top: CGFloat = 140
                
                // Add Summary
                let summaryTitle = L10n.string("summary")
                summaryTitle.draw(at: CGPoint(x: 50, y: top), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)])
                top += 30
                
                var summaryData: [(String, String)] = [
                    (L10n.string("type"), viewModel.calculatorType.rawValue),
                    (self.primaryAmountLabel(for: viewModel), CurrencyFormatter.format(amount: self.primaryAmountValue(for: viewModel), country: viewModel.selectedCountry)),
                    (L10n.interestRate, String(format: "%.2f%%", viewModel.interestRate)),
                    (L10n.string("term"), "\(viewModel.loanTermYears) \(L10n.string("years_short"))")
                ]
                
                if viewModel.downPayment > 0 {
                    summaryData.append((L10n.downPayment, CurrencyFormatter.format(amount: viewModel.downPayment, country: viewModel.selectedCountry)))
                }
                
                // Calculator-specific details
                switch viewModel.calculatorType {
                case .auto, .rv:
                    if viewModel.tradeInValue > 0 {
                        summaryData.append((L10n.tradeInValue, CurrencyFormatter.format(amount: viewModel.tradeInValue, country: viewModel.selectedCountry)))
                    }
                    if viewModel.salesTaxRate > 0 {
                        summaryData.append((L10n.salesTax, String(format: "%.2f%%", viewModel.salesTaxRate)))
                    }
                    if viewModel.registrationFees > 0 {
                        summaryData.append((L10n.registrationFees, CurrencyFormatter.format(amount: viewModel.registrationFees, country: viewModel.selectedCountry)))
                    }
                    
                case .home, .fha:
                    if viewModel.propertyTax > 0 {
                        summaryData.append((L10n.propertyTax, CurrencyFormatter.format(amount: viewModel.propertyTax, country: viewModel.selectedCountry) + L10n.string("per_month")))
                    }
                    if viewModel.homeInsurance > 0 {
                        summaryData.append((L10n.homeInsurance, CurrencyFormatter.format(amount: viewModel.homeInsurance, country: viewModel.selectedCountry) + L10n.string("per_month")))
                    }
                    if viewModel.hoaFees > 0 {
                        summaryData.append((L10n.hoaFees, CurrencyFormatter.format(amount: viewModel.hoaFees, country: viewModel.selectedCountry) + L10n.string("per_month")))
                    }
                    
                case .student:
                    if viewModel.gracePeriodMonths > 0 {
                        summaryData.append((L10n.gracePeriod, "\(viewModel.gracePeriodMonths) \(L10n.string("months_short"))"))
                    }
                    
                case .eligibility:
                    summaryData.append((L10n.string("monthly_income"), CurrencyFormatter.format(amount: viewModel.grossMonthlyIncome, country: viewModel.selectedCountry)))
                    summaryData.append((L10n.monthlyDebts, CurrencyFormatter.format(amount: viewModel.monthlyDebts, country: viewModel.selectedCountry)))
                    summaryData.append((L10n.string("max_affordable_emi"), CurrencyFormatter.format(amount: viewModel.maxMonthlyEMI, country: viewModel.selectedCountry)))
                    summaryData.append((L10n.borrowingPower, CurrencyFormatter.format(amount: viewModel.affordableLoanAmount, country: viewModel.selectedCountry)))
                    
                default:
                    break
                }
                
                // Results section
                summaryData.append((L10n.monthlyPayment, CurrencyFormatter.format(amount: result.monthlyPayment, country: viewModel.selectedCountry)))
                summaryData.append((L10n.totalInterest, CurrencyFormatter.format(amount: result.totalInterest, country: viewModel.selectedCountry)))
                summaryData.append((L10n.totalPayment, CurrencyFormatter.format(amount: result.totalPayment, country: viewModel.selectedCountry)))
                
                for (key, value) in summaryData {
                    let line = "\(key): \(value)"
                    line.draw(at: CGPoint(x: 50, y: top), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
                    top += 20
                }
                
                if includeSchedule {
                    top += 20
                    let scheduleTitle = L10n.amortizationSchedule
                    scheduleTitle.draw(at: CGPoint(x: 50, y: top), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)])
                    top += 30
                    
                    // Helper to draw headers
                    func drawHeaders(at y: CGFloat) {
                        let headers = [L10n.month, L10n.principal, L10n.interest, L10n.balance]
                        for (i, header) in headers.enumerated() {
                            header.draw(at: CGPoint(x: 50 + CGFloat(i * 125), y: y), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12)])
                        }
                    }
                    
                    drawHeaders(at: top)
                    top += 20
                    
                    // Table Content
                    for entry in result.amortizationSchedule {
                        if top > 730 { // Leave margin for footer
                            context.beginPage()
                            
                            // Mini header for subsequent pages
                            let miniHeader = "LoanPro 2025 - Amortization Schedule"
                            miniHeader.draw(at: CGPoint(x: 50, y: 20), withAttributes: [
                                .font: UIFont.systemFont(ofSize: 10),
                                .foregroundColor: UIColor.secondaryLabel
                            ])
                            
                            top = 50
                            drawHeaders(at: top)
                            top += 25
                        }
                        
                        let items = [
                            "\(entry.month)",
                            CurrencyFormatter.format(amount: entry.principal, country: viewModel.selectedCountry),
                            CurrencyFormatter.format(amount: entry.interest, country: viewModel.selectedCountry),
                            CurrencyFormatter.format(amount: entry.balance, country: viewModel.selectedCountry)
                        ]
                        
                        for (i, item) in items.enumerated() {
                            item.draw(at: CGPoint(x: 50 + CGFloat(i * 125), y: top), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
                        }
                        top += 18
                    }
                }
            }
            return path
        } catch {
            print("Failed to create PDF: \(error)")
            return nil
        }
    }
}
