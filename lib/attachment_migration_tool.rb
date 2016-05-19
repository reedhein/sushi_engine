class AttachmentMigrationTool
  def initialize(zoho_sushi, sales_force_sushi)
    @zoho_sushi        = zoho_sushi
    @sales_force_sushi = sales_force_sushi
  end

  def perform
    attachments = @zoho_sushi.attachments
    attachments.map do |attachment|
      @sales_force_sushi.attach(@zoho_sushi, attachment)
    end
    @zoho_sushi.mark_completed
    @sales_force_sushi.mark_completed
  end

  def save_local
  end
end
