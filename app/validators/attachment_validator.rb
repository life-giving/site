# validates :file, attachment: { kind: :pdf }
# The type is sniffed from the file's bytes alone: Active Storage's own detection
# falls back to the filename, so text renamed to .pdf would pass as a PDF.
class AttachmentValidator < ActiveModel::EachValidator
  KINDS = {
    image: { types: %w[image/jpeg image/png image/webp], limit: :max_image_size_mb, label: "JPEG, PNG, WebP" },
    pdf: { types: %w[application/pdf], limit: :max_pdf_size_mb, label: "PDF" }
  }.freeze
  SNIFF_BYTES = 4.kilobytes

  def validate_each(record, attribute, attachment)
    return record.errors.add(attribute, :blank) unless attachment.attached?
    # Files already stored keep passing if a limit is lowered later.
    return unless record.attachment_changes.key?(attribute.to_s)

    kind = KINDS.fetch(options.fetch(:kind))
    max_mb = Rails.configuration.x.uploads.fetch(kind[:limit]).to_i
    record.errors.add(attribute, :too_large, max_mb: max_mb) if attachment.blob.byte_size > max_mb.megabytes

    unless kind[:types].include?(content_type(record, attribute, attachment))
      record.errors.add(attribute, :invalid_type, allowed: kind[:label])
    end
  end

  private

  def content_type(record, attribute, attachment)
    pending = record.attachment_changes[attribute.to_s]&.attachable
    io = pending.is_a?(Hash) ? pending[:io] : pending
    return attachment.blob.content_type unless io.respond_to?(:read)

    io.rewind
    head = io.read(SNIFF_BYTES)
    io.rewind
    Marcel::MimeType.for(StringIO.new(head.to_s))
  end
end
