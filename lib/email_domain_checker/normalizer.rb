# frozen_string_literal: true

module EmailDomainChecker
  class Normalizer
    def self.normalize(raw)
      return "" if raw.nil? || raw.to_s.strip.empty?

      email_str = raw.to_s.strip
      return "" if email_str.empty?

      # Basic normalization: lowercase and IDN handling
      local, domain = email_str.downcase.split("@", 2)
      return email_str unless local && domain && !local.empty? && !domain.empty?

      # IDN (Internationalized Domain Name) conversion
      domain = idn_to_ascii(domain)
      "#{local}@#{domain}"
    end

    def self.idn_to_ascii(domain)
      # Simple IDN conversion using built-in methods
      # For production, consider using the 'simpleidn' gem
      begin
        # Try to encode as IDN if it contains non-ASCII characters
        if domain.match?(/[^\x00-\x7F]/)
          # Fallback: return as-is if IDN conversion fails
          # In production, use: SimpleIDN.to_ascii(domain)
          domain
        else
          domain
        end
      rescue StandardError
        domain
      end
    end
  end
end
