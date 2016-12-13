module Gourami
  module FormattingConstants

    EMAIL_FORMAT = (/\A
      ([0-9a-zA-Z\.][-\w\+\.]*)@
      ([0-9a-zA-Z_][-\w]*[0-9a-zA-Z]*\.)+[a-zA-Z]{2,9}\z/x).freeze

    ISRC_FORMAT = (/\A[a-zA-Z]{2}[a-zA-Z0-9]{5}[0-9]{5}\z/).freeze

    HEX_COLOR_FORMAT = (/^#([A-F0-9]{3}|[A-F0-9]{6})$/i).freeze

  end
end
