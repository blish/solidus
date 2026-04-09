# frozen_string_literal: true

module GearedPagination
  module RecordsetPatch
    private

    def records_count
      @records_count ||= records.unscope(:limit, :offset, :select, :order).count
    end

    GearedPagination::Recordset.prepend self
  end
end