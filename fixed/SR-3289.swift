import Foundation

let url = URL(fileURLWithPath: "file")
var values = URLResourceValues()
values.isExcludedFromBackup = true
try? url.setResourceValues(values)

