require "test_helper"

class LocaleFilesTest < ActiveSupport::TestCase
  def flat_keys(value, prefix = "")
    case value
    when Hash then value.flat_map { |key, child| flat_keys(child, "#{prefix}.#{key}") }
    when Array then value.each_with_index.flat_map { |child, index| flat_keys(child, "#{prefix}[#{index}]") }
    else [ prefix ]
    end
  end

  def flat_values(value)
    case value
    when Hash then value.values.flat_map { |child| flat_values(child) }
    when Array then value.flat_map { |child| flat_values(child) }
    else [ value ]
    end
  end

  def site_keys(locale)
    flat_keys(I18n.t("site", locale: locale)).sort
  end

  test "site text has the same keys in both languages" do
    assert_equal site_keys(:uk), site_keys(:en)
  end

  test "no site text is blank" do
    %i[uk en].each do |locale|
      flat_values(I18n.t("site", locale: locale)).each { |value| assert_predicate value.to_s, :present? }
    end
  end
end
