namespace :documents do
  desc "Show percentage of null values for each column in the documents table"
  task null_percentages: :environment do
    documents_count = Document.count
    columns = Document.column_names

    puts "\nAnalyzing null values in documents table (#{documents_count} total records)\n\n"

    # Calculate max column name length for formatting
    max_length = columns.map(&:length).max

    # Print header
    header = "Column Name".ljust(max_length) + " | Total Records | Null Count | Null %"
    puts header
    puts "-" * header.length

    # Calculate and display stats for each column
    columns.each do |column|
      null_count = Document.where(column => nil).count
      percentage = documents_count.zero? ? 0 : (null_count.to_f / documents_count * 100).round(1)

      row = [
        column.ljust(max_length),
        documents_count.to_s.rjust(12),
        null_count.to_s.rjust(9),
        "#{percentage.to_s.rjust(5)}%"
      ].join(" | ")
      puts row
    end

    puts "\n"
  end
end
