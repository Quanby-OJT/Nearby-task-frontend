export interface PaymentLog {
  payment_id: string;
  user_name: string;
  amount: string;
  payment_type: string;
  transaction_date: string
  created_at: string;
}

export interface WithdrawalDetails {
  created_at: string;
  name: string;
  object: string;
  private_notes: string;
  recipients_count: number;
  reference_id: string;
  status: string;
}

export interface DepositDetails {
  payment_details: {
    id: string;
    type: string;
    attributes: {
      amount: number;
      capture_type: string;
      client_key: string;
      currency: string;
      description: string;
      livemode: boolean;
      original_amount: number;
      statement_descriptor: string;
      status: string;
      last_payment_error: null;
      payment_method_allowed: string[];
      payments: Array<{
        id: string;
        type: string;
        attributes: {
          access_url: null;
          amount: number;
          balance_transaction_id: string;
          billing: {
            address: {
              city: string | null;
              country: string | null;
              line1: string | null;
              line2: string | null;
              postal_code: string | null;
              state: string | null;
            };
            email: string;
            name: string;
            phone: string;
          };
          currency: string;
          description: string;
          disputed: boolean;
          external_reference_number: null;
          fee: number;
          instant_settlement: null;
          livemode: boolean;
          net_amount: number;
          origin: string;
          payment_intent_id: string;
          payout: null;
          source: {
            id: string;
            type: string;
            provider: {
              id: null;
            };
            provider_id: null;
          };
          statement_descriptor: string;
          status: string;
          tax_amount: null;
          metadata: null;
          promotion: null;
          refunds: any[];
          taxes: any[];
          available_at: number;
          created_at: number;
          credited_at: number;
          paid_at: number;
          updated_at: number;
        };
      }>;
      next_action: null;
      payment_method_options: null;
      metadata: null;
      setup_future_usage: null;
      created_at: number;
      updated_at: number;
    };
  }
}
