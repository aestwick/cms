export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.1"
  }
  public: {
    Tables: {
      access_requests: {
        Row: {
          approved_role: string | null
          created_at: string
          deleted_at: string | null
          display_name: string | null
          email: string
          id: string
          reviewed_at: string | null
          reviewed_by: string | null
          reviewer_note: string | null
          station_id: string | null
          station_role_description: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          approved_role?: string | null
          created_at?: string
          deleted_at?: string | null
          display_name?: string | null
          email: string
          id?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          reviewer_note?: string | null
          station_id?: string | null
          station_role_description?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          approved_role?: string | null
          created_at?: string
          deleted_at?: string | null
          display_name?: string | null
          email?: string
          id?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          reviewer_note?: string | null
          station_id?: string | null
          station_role_description?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "access_requests_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      addresses: {
        Row: {
          address_type: string
          city: string
          country: string
          created_at: string
          deleted_at: string | null
          donor_id: string
          id: string
          is_default: boolean
          is_verified: boolean
          label: string | null
          postal_code: string
          recipient_email: string | null
          recipient_name: string | null
          recipient_phone: string | null
          state: string
          street_line_1: string
          street_line_2: string | null
          updated_at: string
          verified_at: string | null
        }
        Insert: {
          address_type?: string
          city: string
          country?: string
          created_at?: string
          deleted_at?: string | null
          donor_id: string
          id?: string
          is_default?: boolean
          is_verified?: boolean
          label?: string | null
          postal_code: string
          recipient_email?: string | null
          recipient_name?: string | null
          recipient_phone?: string | null
          state: string
          street_line_1: string
          street_line_2?: string | null
          updated_at?: string
          verified_at?: string | null
        }
        Update: {
          address_type?: string
          city?: string
          country?: string
          created_at?: string
          deleted_at?: string | null
          donor_id?: string
          id?: string
          is_default?: boolean
          is_verified?: boolean
          label?: string | null
          postal_code?: string
          recipient_email?: string | null
          recipient_name?: string | null
          recipient_phone?: string | null
          state?: string
          street_line_1?: string
          street_line_2?: string | null
          updated_at?: string
          verified_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "addresses_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_log: {
        Row: {
          action: string
          created_at: string
          id: string
          ip_address: unknown
          new_data: Json | null
          old_data: Json | null
          record_id: string | null
          station_id: string | null
          table_name: string
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          action: string
          created_at?: string
          id?: string
          ip_address?: unknown
          new_data?: Json | null
          old_data?: Json | null
          record_id?: string | null
          station_id?: string | null
          table_name: string
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          action?: string
          created_at?: string
          id?: string
          ip_address?: unknown
          new_data?: Json | null
          old_data?: Json | null
          record_id?: string | null
          station_id?: string | null
          table_name?: string
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "audit_log_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "audit_log_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      campaign_shows: {
        Row: {
          campaign_id: string
          created_at: string
          goal_cents: number | null
          id: string
          show_id: string
          station_id: string
        }
        Insert: {
          campaign_id: string
          created_at?: string
          goal_cents?: number | null
          id?: string
          show_id: string
          station_id: string
        }
        Update: {
          campaign_id?: string
          created_at?: string
          goal_cents?: number | null
          id?: string
          show_id?: string
          station_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "campaign_shows_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_shows_show_id_fkey"
            columns: ["show_id"]
            isOneToOne: false
            referencedRelation: "shows"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_shows_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      campaigns: {
        Row: {
          campaign_type: string
          code: string
          created_at: string
          deleted_at: string | null
          description: string | null
          ends_at: string | null
          goal_cents: number | null
          goal_donors: number | null
          goal_sustainers: number | null
          id: string
          is_active: boolean
          name: string
          starts_at: string | null
          station_id: string
          updated_at: string
        }
        Insert: {
          campaign_type?: string
          code: string
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          ends_at?: string | null
          goal_cents?: number | null
          goal_donors?: number | null
          goal_sustainers?: number | null
          id?: string
          is_active?: boolean
          name: string
          starts_at?: string | null
          station_id: string
          updated_at?: string
        }
        Update: {
          campaign_type?: string
          code?: string
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          ends_at?: string | null
          goal_cents?: number | null
          goal_donors?: number | null
          goal_sustainers?: number | null
          id?: string
          is_active?: boolean
          name?: string
          starts_at?: string | null
          station_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "campaigns_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      checkout_sessions: {
        Row: {
          completed_at: string | null
          created_at: string
          donation_id: string | null
          donation_snapshot: Json
          donor_id: string | null
          donor_snapshot: Json
          expires_at: string | null
          id: string
          mode: string
          operator_id: string | null
          station_id: string
          status: string
          stripe_checkout_session_id: string | null
          updated_at: string
        }
        Insert: {
          completed_at?: string | null
          created_at?: string
          donation_id?: string | null
          donation_snapshot?: Json
          donor_id?: string | null
          donor_snapshot?: Json
          expires_at?: string | null
          id?: string
          mode: string
          operator_id?: string | null
          station_id: string
          status?: string
          stripe_checkout_session_id?: string | null
          updated_at?: string
        }
        Update: {
          completed_at?: string | null
          created_at?: string
          donation_id?: string | null
          donation_snapshot?: Json
          donor_id?: string | null
          donor_snapshot?: Json
          expires_at?: string | null
          id?: string
          mode?: string
          operator_id?: string | null
          station_id?: string
          status?: string
          stripe_checkout_session_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "checkout_sessions_donation_id_fkey"
            columns: ["donation_id"]
            isOneToOne: false
            referencedRelation: "donations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checkout_sessions_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checkout_sessions_operator_id_fkey"
            columns: ["operator_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checkout_sessions_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      documents: {
        Row: {
          created_at: string
          deleted_at: string | null
          description: string | null
          document_type: string
          donor_id: string | null
          effective_date: string | null
          expiration_date: string | null
          file_name: string
          file_size_bytes: number | null
          file_url: string
          id: string
          mime_type: string | null
          signed_by: string[] | null
          signed_date: string | null
          station_id: string
          status: string
          supersedes_id: string | null
          title: string
          updated_at: string
          uploaded_by: string
          visibility_level: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          document_type: string
          donor_id?: string | null
          effective_date?: string | null
          expiration_date?: string | null
          file_name: string
          file_size_bytes?: number | null
          file_url: string
          id?: string
          mime_type?: string | null
          signed_by?: string[] | null
          signed_date?: string | null
          station_id: string
          status?: string
          supersedes_id?: string | null
          title: string
          updated_at?: string
          uploaded_by: string
          visibility_level?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          document_type?: string
          donor_id?: string | null
          effective_date?: string | null
          expiration_date?: string | null
          file_name?: string
          file_size_bytes?: number | null
          file_url?: string
          id?: string
          mime_type?: string | null
          signed_by?: string[] | null
          signed_date?: string | null
          station_id?: string
          status?: string
          supersedes_id?: string | null
          title?: string
          updated_at?: string
          uploaded_by?: string
          visibility_level?: string
        }
        Relationships: [
          {
            foreignKeyName: "documents_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "documents_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "documents_supersedes_id_fkey"
            columns: ["supersedes_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "documents_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      donation_inspirations: {
        Row: {
          category_id: string | null
          created_at: string
          donation_id: string
          host_id: string | null
          id: string
          program_id: string | null
          raw_value: string
        }
        Insert: {
          category_id?: string | null
          created_at?: string
          donation_id: string
          host_id?: string | null
          id?: string
          program_id?: string | null
          raw_value: string
        }
        Update: {
          category_id?: string | null
          created_at?: string
          donation_id?: string
          host_id?: string | null
          id?: string
          program_id?: string | null
          raw_value?: string
        }
        Relationships: [
          {
            foreignKeyName: "donation_inspirations_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "program_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donation_inspirations_donation_id_fkey"
            columns: ["donation_id"]
            isOneToOne: false
            referencedRelation: "donations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donation_inspirations_host_id_fkey"
            columns: ["host_id"]
            isOneToOne: false
            referencedRelation: "program_hosts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donation_inspirations_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      donations: {
        Row: {
          amount_cents: number
          campaign_id: string | null
          check_number: string | null
          checkout_session_id: string | null
          comments: string | null
          created_at: string
          currency: string
          deleted_at: string | null
          donor_id: string
          fee_coverage_cents: number
          gift_id: string | null
          gift_variant_id: string | null
          id: string
          is_first_donation: boolean | null
          operator_id: string | null
          payment_due_at: string | null
          payment_method_type: string | null
          payment_provider: string
          pledged_at: string | null
          received_at: string | null
          recipient_donor_id: string | null
          referrer_url: string | null
          show_id: string | null
          source_code: string | null
          source_type: string | null
          station_id: string
          status: string
          stripe_payment_intent_id: string | null
          updated_at: string
          utm_campaign: string | null
          utm_medium: string | null
          utm_source: string | null
        }
        Insert: {
          amount_cents: number
          campaign_id?: string | null
          check_number?: string | null
          checkout_session_id?: string | null
          comments?: string | null
          created_at?: string
          currency?: string
          deleted_at?: string | null
          donor_id: string
          fee_coverage_cents?: number
          gift_id?: string | null
          gift_variant_id?: string | null
          id?: string
          is_first_donation?: boolean | null
          operator_id?: string | null
          payment_due_at?: string | null
          payment_method_type?: string | null
          payment_provider: string
          pledged_at?: string | null
          received_at?: string | null
          recipient_donor_id?: string | null
          referrer_url?: string | null
          show_id?: string | null
          source_code?: string | null
          source_type?: string | null
          station_id: string
          status?: string
          stripe_payment_intent_id?: string | null
          updated_at?: string
          utm_campaign?: string | null
          utm_medium?: string | null
          utm_source?: string | null
        }
        Update: {
          amount_cents?: number
          campaign_id?: string | null
          check_number?: string | null
          checkout_session_id?: string | null
          comments?: string | null
          created_at?: string
          currency?: string
          deleted_at?: string | null
          donor_id?: string
          fee_coverage_cents?: number
          gift_id?: string | null
          gift_variant_id?: string | null
          id?: string
          is_first_donation?: boolean | null
          operator_id?: string | null
          payment_due_at?: string | null
          payment_method_type?: string | null
          payment_provider?: string
          pledged_at?: string | null
          received_at?: string | null
          recipient_donor_id?: string | null
          referrer_url?: string | null
          show_id?: string | null
          source_code?: string | null
          source_type?: string | null
          station_id?: string
          status?: string
          stripe_payment_intent_id?: string | null
          updated_at?: string
          utm_campaign?: string | null
          utm_medium?: string | null
          utm_source?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "donations_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donations_checkout_session_id_fkey"
            columns: ["checkout_session_id"]
            isOneToOne: false
            referencedRelation: "checkout_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donations_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donations_gift_id_fkey"
            columns: ["gift_id"]
            isOneToOne: false
            referencedRelation: "gifts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donations_gift_variant_id_fkey"
            columns: ["gift_variant_id"]
            isOneToOne: false
            referencedRelation: "gift_variants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donations_operator_id_fkey"
            columns: ["operator_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donations_recipient_donor_id_fkey"
            columns: ["recipient_donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donations_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      donor_extensions: {
        Row: {
          board_member: boolean
          capacity_source: string | null
          contact_preferences: Json
          created_at: string
          donor_id: string
          donor_type: string
          estimated_capacity_cents: number | null
          id: string
          largest_gift_cents: number | null
          last_contact_date: string | null
          last_gift_date: string | null
          recognition_preferences: Json
          relationship_owner_id: string | null
          risk_level: string | null
          risk_notes: string | null
          secondary_owner_id: string | null
          total_lifetime_cents: number
          updated_at: string
          vip_flag: boolean
        }
        Insert: {
          board_member?: boolean
          capacity_source?: string | null
          contact_preferences?: Json
          created_at?: string
          donor_id: string
          donor_type?: string
          estimated_capacity_cents?: number | null
          id?: string
          largest_gift_cents?: number | null
          last_contact_date?: string | null
          last_gift_date?: string | null
          recognition_preferences?: Json
          relationship_owner_id?: string | null
          risk_level?: string | null
          risk_notes?: string | null
          secondary_owner_id?: string | null
          total_lifetime_cents?: number
          updated_at?: string
          vip_flag?: boolean
        }
        Update: {
          board_member?: boolean
          capacity_source?: string | null
          contact_preferences?: Json
          created_at?: string
          donor_id?: string
          donor_type?: string
          estimated_capacity_cents?: number | null
          id?: string
          largest_gift_cents?: number | null
          last_contact_date?: string | null
          last_gift_date?: string | null
          recognition_preferences?: Json
          relationship_owner_id?: string | null
          risk_level?: string | null
          risk_notes?: string | null
          secondary_owner_id?: string | null
          total_lifetime_cents?: number
          updated_at?: string
          vip_flag?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "donor_extensions_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: true
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donor_extensions_relationship_owner_id_fkey"
            columns: ["relationship_owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donor_extensions_secondary_owner_id_fkey"
            columns: ["secondary_owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      donor_notes: {
        Row: {
          author_id: string | null
          body: string
          created_at: string
          deleted_at: string | null
          donor_id: string
          id: string
          is_pinned: boolean
          note_type: string
          subject: string | null
          supersedes_id: string | null
          updated_at: string
        }
        Insert: {
          author_id?: string | null
          body: string
          created_at?: string
          deleted_at?: string | null
          donor_id: string
          id?: string
          is_pinned?: boolean
          note_type?: string
          subject?: string | null
          supersedes_id?: string | null
          updated_at?: string
        }
        Update: {
          author_id?: string | null
          body?: string
          created_at?: string
          deleted_at?: string | null
          donor_id?: string
          id?: string
          is_pinned?: boolean
          note_type?: string
          subject?: string | null
          supersedes_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "donor_notes_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donor_notes_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donor_notes_supersedes_id_fkey"
            columns: ["supersedes_id"]
            isOneToOne: false
            referencedRelation: "donor_notes"
            referencedColumns: ["id"]
          },
        ]
      }
      donor_tags: {
        Row: {
          applied_by: string | null
          created_at: string
          deleted_at: string | null
          donor_id: string
          id: string
          tag: string
        }
        Insert: {
          applied_by?: string | null
          created_at?: string
          deleted_at?: string | null
          donor_id: string
          id?: string
          tag: string
        }
        Update: {
          applied_by?: string | null
          created_at?: string
          deleted_at?: string | null
          donor_id?: string
          id?: string
          tag?: string
        }
        Relationships: [
          {
            foreignKeyName: "donor_tags_applied_by_fkey"
            columns: ["applied_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "donor_tags_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
        ]
      }
      donors: {
        Row: {
          city: string | null
          created_at: string
          deleted_at: string | null
          email: string
          email_normalized: string
          first_name: string | null
          id: string
          last_name: string | null
          phone: string | null
          preferences: Json
          source: string | null
          state: string | null
          station_id: string
          stripe_customer_id: string | null
          updated_at: string
          zip: string | null
        }
        Insert: {
          city?: string | null
          created_at?: string
          deleted_at?: string | null
          email: string
          email_normalized: string
          first_name?: string | null
          id?: string
          last_name?: string | null
          phone?: string | null
          preferences?: Json
          source?: string | null
          state?: string | null
          station_id: string
          stripe_customer_id?: string | null
          updated_at?: string
          zip?: string | null
        }
        Update: {
          city?: string | null
          created_at?: string
          deleted_at?: string | null
          email?: string
          email_normalized?: string
          first_name?: string | null
          id?: string
          last_name?: string | null
          phone?: string | null
          preferences?: Json
          source?: string | null
          state?: string | null
          station_id?: string
          stripe_customer_id?: string | null
          updated_at?: string
          zip?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "donors_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      email_log: {
        Row: {
          created_at: string
          delivered_at: string | null
          donation_id: string | null
          donor_id: string | null
          external_id: string | null
          id: string
          recipient_email: string
          sent_at: string | null
          station_id: string
          status: string
          status_detail: string | null
          subject: string | null
          template_name: string
          template_version: string | null
        }
        Insert: {
          created_at?: string
          delivered_at?: string | null
          donation_id?: string | null
          donor_id?: string | null
          external_id?: string | null
          id?: string
          recipient_email: string
          sent_at?: string | null
          station_id: string
          status?: string
          status_detail?: string | null
          subject?: string | null
          template_name: string
          template_version?: string | null
        }
        Update: {
          created_at?: string
          delivered_at?: string | null
          donation_id?: string | null
          donor_id?: string | null
          external_id?: string | null
          id?: string
          recipient_email?: string
          sent_at?: string | null
          station_id?: string
          status?: string
          status_detail?: string | null
          subject?: string | null
          template_name?: string
          template_version?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "email_log_donation_id_fkey"
            columns: ["donation_id"]
            isOneToOne: false
            referencedRelation: "donations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_log_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_log_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      event_registration_gifts: {
        Row: {
          created_at: string
          fulfillment_item_id: string | null
          gift_variant_id: string
          id: string
          quantity: number
          registration_id: string
        }
        Insert: {
          created_at?: string
          fulfillment_item_id?: string | null
          gift_variant_id: string
          id?: string
          quantity?: number
          registration_id: string
        }
        Update: {
          created_at?: string
          fulfillment_item_id?: string | null
          gift_variant_id?: string
          id?: string
          quantity?: number
          registration_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "event_registration_gifts_fulfillment_item_id_fkey"
            columns: ["fulfillment_item_id"]
            isOneToOne: false
            referencedRelation: "fulfillment_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_registration_gifts_gift_variant_id_fkey"
            columns: ["gift_variant_id"]
            isOneToOne: false
            referencedRelation: "gift_variants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_registration_gifts_registration_id_fkey"
            columns: ["registration_id"]
            isOneToOne: false
            referencedRelation: "event_registrations"
            referencedColumns: ["id"]
          },
        ]
      }
      event_registrations: {
        Row: {
          attendee_email: string
          attendee_name: string
          attendee_phone: string | null
          cancelled_at: string | null
          checked_in: boolean
          checked_in_at: string | null
          checked_in_by: string | null
          confirmed_at: string | null
          created_at: string
          deleted_at: string | null
          discount_cents: number
          donation_id: string | null
          donor_id: string | null
          event_id: string
          id: string
          internal_notes: string | null
          promo_code_id: string | null
          quantity: number
          special_requests: string | null
          status: string
          ticket_type_id: string
          total_cents: number
          unit_price_cents: number
          updated_at: string
        }
        Insert: {
          attendee_email: string
          attendee_name: string
          attendee_phone?: string | null
          cancelled_at?: string | null
          checked_in?: boolean
          checked_in_at?: string | null
          checked_in_by?: string | null
          confirmed_at?: string | null
          created_at?: string
          deleted_at?: string | null
          discount_cents?: number
          donation_id?: string | null
          donor_id?: string | null
          event_id: string
          id?: string
          internal_notes?: string | null
          promo_code_id?: string | null
          quantity?: number
          special_requests?: string | null
          status?: string
          ticket_type_id: string
          total_cents: number
          unit_price_cents: number
          updated_at?: string
        }
        Update: {
          attendee_email?: string
          attendee_name?: string
          attendee_phone?: string | null
          cancelled_at?: string | null
          checked_in?: boolean
          checked_in_at?: string | null
          checked_in_by?: string | null
          confirmed_at?: string | null
          created_at?: string
          deleted_at?: string | null
          discount_cents?: number
          donation_id?: string | null
          donor_id?: string | null
          event_id?: string
          id?: string
          internal_notes?: string | null
          promo_code_id?: string | null
          quantity?: number
          special_requests?: string | null
          status?: string
          ticket_type_id?: string
          total_cents?: number
          unit_price_cents?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "event_registrations_checked_in_by_fkey"
            columns: ["checked_in_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_registrations_donation_id_fkey"
            columns: ["donation_id"]
            isOneToOne: false
            referencedRelation: "donations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_registrations_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_registrations_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_registrations_promo_code_id_fkey"
            columns: ["promo_code_id"]
            isOneToOne: false
            referencedRelation: "promo_codes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_registrations_ticket_type_id_fkey"
            columns: ["ticket_type_id"]
            isOneToOne: false
            referencedRelation: "ticket_types"
            referencedColumns: ["id"]
          },
        ]
      }
      events: {
        Row: {
          allow_waitlist: boolean
          campaign_id: string | null
          created_at: string
          deleted_at: string | null
          description: string | null
          doors_open_at: string | null
          ends_at: string | null
          id: string
          image_url: string | null
          is_virtual: boolean
          name: string
          published_at: string | null
          registration_closes_at: string | null
          registration_opens_at: string | null
          show_id: string | null
          slug: string
          starts_at: string
          station_id: string
          status: string
          timezone: string
          total_capacity: number | null
          updated_at: string
          venue_address: string | null
          venue_city: string | null
          venue_name: string | null
          venue_postal: string | null
          venue_state: string | null
          virtual_url: string | null
        }
        Insert: {
          allow_waitlist?: boolean
          campaign_id?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          doors_open_at?: string | null
          ends_at?: string | null
          id?: string
          image_url?: string | null
          is_virtual?: boolean
          name: string
          published_at?: string | null
          registration_closes_at?: string | null
          registration_opens_at?: string | null
          show_id?: string | null
          slug: string
          starts_at: string
          station_id: string
          status?: string
          timezone?: string
          total_capacity?: number | null
          updated_at?: string
          venue_address?: string | null
          venue_city?: string | null
          venue_name?: string | null
          venue_postal?: string | null
          venue_state?: string | null
          virtual_url?: string | null
        }
        Update: {
          allow_waitlist?: boolean
          campaign_id?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          doors_open_at?: string | null
          ends_at?: string | null
          id?: string
          image_url?: string | null
          is_virtual?: boolean
          name?: string
          published_at?: string | null
          registration_closes_at?: string | null
          registration_opens_at?: string | null
          show_id?: string | null
          slug?: string
          starts_at?: string
          station_id?: string
          status?: string
          timezone?: string
          total_capacity?: number | null
          updated_at?: string
          venue_address?: string | null
          venue_city?: string | null
          venue_name?: string | null
          venue_postal?: string | null
          venue_state?: string | null
          virtual_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "events_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_show_id_fkey"
            columns: ["show_id"]
            isOneToOne: false
            referencedRelation: "shows"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      feedback_responses: {
        Row: {
          created_at: string
          deleted_at: string | null
          donation_id: string | null
          donor_id: string | null
          form_type: string
          fulfillment_item_id: string | null
          id: string
          membership_id: string | null
          message: string | null
          metadata: Json | null
          rating: number | null
          selections: Json | null
          station_id: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          donation_id?: string | null
          donor_id?: string | null
          form_type: string
          fulfillment_item_id?: string | null
          id?: string
          membership_id?: string | null
          message?: string | null
          metadata?: Json | null
          rating?: number | null
          selections?: Json | null
          station_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          donation_id?: string | null
          donor_id?: string | null
          form_type?: string
          fulfillment_item_id?: string | null
          id?: string
          membership_id?: string | null
          message?: string | null
          metadata?: Json | null
          rating?: number | null
          selections?: Json | null
          station_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "feedback_responses_donation_id_fkey"
            columns: ["donation_id"]
            isOneToOne: false
            referencedRelation: "donations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feedback_responses_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feedback_responses_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      fulfillment_items: {
        Row: {
          address_id: string | null
          address_snapshot: Json | null
          assigned_at: string | null
          assigned_to: string | null
          cancellation_reason: string | null
          cancelled_at: string | null
          carrier: string | null
          created_at: string
          deleted_at: string | null
          delivered_at: string | null
          donation_id: string
          gift_variant_id: string
          id: string
          internal_notes: string | null
          processing_at: string | null
          quantity: number
          shipped_at: string | null
          status: string
          tracking_number: string | null
          tracking_url: string | null
          updated_at: string
        }
        Insert: {
          address_id?: string | null
          address_snapshot?: Json | null
          assigned_at?: string | null
          assigned_to?: string | null
          cancellation_reason?: string | null
          cancelled_at?: string | null
          carrier?: string | null
          created_at?: string
          deleted_at?: string | null
          delivered_at?: string | null
          donation_id: string
          gift_variant_id: string
          id?: string
          internal_notes?: string | null
          processing_at?: string | null
          quantity?: number
          shipped_at?: string | null
          status?: string
          tracking_number?: string | null
          tracking_url?: string | null
          updated_at?: string
        }
        Update: {
          address_id?: string | null
          address_snapshot?: Json | null
          assigned_at?: string | null
          assigned_to?: string | null
          cancellation_reason?: string | null
          cancelled_at?: string | null
          carrier?: string | null
          created_at?: string
          deleted_at?: string | null
          delivered_at?: string | null
          donation_id?: string
          gift_variant_id?: string
          id?: string
          internal_notes?: string | null
          processing_at?: string | null
          quantity?: number
          shipped_at?: string | null
          status?: string
          tracking_number?: string | null
          tracking_url?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fulfillment_items_address_id_fkey"
            columns: ["address_id"]
            isOneToOne: false
            referencedRelation: "addresses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fulfillment_items_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fulfillment_items_donation_id_fkey"
            columns: ["donation_id"]
            isOneToOne: false
            referencedRelation: "donations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fulfillment_items_gift_variant_id_fkey"
            columns: ["gift_variant_id"]
            isOneToOne: false
            referencedRelation: "gift_variants"
            referencedColumns: ["id"]
          },
        ]
      }
      gift_campaigns: {
        Row: {
          campaign_id: string
          created_at: string
          gift_id: string
          id: string
        }
        Insert: {
          campaign_id: string
          created_at?: string
          gift_id: string
          id?: string
        }
        Update: {
          campaign_id?: string
          created_at?: string
          gift_id?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "gift_campaigns_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "gift_campaigns_gift_id_fkey"
            columns: ["gift_id"]
            isOneToOne: false
            referencedRelation: "gifts"
            referencedColumns: ["id"]
          },
        ]
      }
      gift_intents: {
        Row: {
          confidence_level: string
          created_at: string
          document_id: string | null
          donor_id: string
          evidence_date: string
          evidence_notes: string | null
          evidence_type: string
          expected_date: string | null
          expected_timeframe: string | null
          has_restrictions: boolean
          id: string
          intent_type: string
          recorded_by: string
          restriction_details: string | null
          stated_amount_cents: number | null
          stated_amount_range: string | null
          station_id: string
          superseded_at: string | null
          supersedes_id: string | null
        }
        Insert: {
          confidence_level?: string
          created_at?: string
          document_id?: string | null
          donor_id: string
          evidence_date: string
          evidence_notes?: string | null
          evidence_type: string
          expected_date?: string | null
          expected_timeframe?: string | null
          has_restrictions?: boolean
          id?: string
          intent_type: string
          recorded_by: string
          restriction_details?: string | null
          stated_amount_cents?: number | null
          stated_amount_range?: string | null
          station_id: string
          superseded_at?: string | null
          supersedes_id?: string | null
        }
        Update: {
          confidence_level?: string
          created_at?: string
          document_id?: string | null
          donor_id?: string
          evidence_date?: string
          evidence_notes?: string | null
          evidence_type?: string
          expected_date?: string | null
          expected_timeframe?: string | null
          has_restrictions?: boolean
          id?: string
          intent_type?: string
          recorded_by?: string
          restriction_details?: string | null
          stated_amount_cents?: number | null
          stated_amount_range?: string | null
          station_id?: string
          superseded_at?: string | null
          supersedes_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "gift_intents_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "gift_intents_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "gift_intents_recorded_by_fkey"
            columns: ["recorded_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "gift_intents_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "gift_intents_supersedes_id_fkey"
            columns: ["supersedes_id"]
            isOneToOne: false
            referencedRelation: "gift_intents"
            referencedColumns: ["id"]
          },
        ]
      }
      gift_programs: {
        Row: {
          created_at: string
          gift_id: string
          id: string
          program_id: string
        }
        Insert: {
          created_at?: string
          gift_id: string
          id?: string
          program_id: string
        }
        Update: {
          created_at?: string
          gift_id?: string
          id?: string
          program_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "gift_programs_gift_id_fkey"
            columns: ["gift_id"]
            isOneToOne: false
            referencedRelation: "gifts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "gift_programs_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      gift_variants: {
        Row: {
          created_at: string
          deleted_at: string | null
          gift_id: string
          id: string
          inventory_count: number | null
          inventory_incoming: number | null
          inventory_unavailable: number | null
          is_active: boolean
          low_stock_threshold: number | null
          name: string
          reorder_point: number | null
          sku: string | null
          sort_order: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          gift_id: string
          id?: string
          inventory_count?: number | null
          inventory_incoming?: number | null
          inventory_unavailable?: number | null
          is_active?: boolean
          low_stock_threshold?: number | null
          name: string
          reorder_point?: number | null
          sku?: string | null
          sort_order?: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          gift_id?: string
          id?: string
          inventory_count?: number | null
          inventory_incoming?: number | null
          inventory_unavailable?: number | null
          is_active?: boolean
          low_stock_threshold?: number | null
          name?: string
          reorder_point?: number | null
          sku?: string | null
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "gift_variants_gift_id_fkey"
            columns: ["gift_id"]
            isOneToOne: false
            referencedRelation: "gifts"
            referencedColumns: ["id"]
          },
        ]
      }
      gifts: {
        Row: {
          category: string | null
          cogs_cents: number
          created_at: string
          deleted_at: string | null
          description: string | null
          expires_at: string | null
          fmv_cents: number
          fulfillment_method: string
          id: string
          image_url: string | null
          is_active: boolean
          is_exclusive: boolean
          is_featured: boolean
          is_hidden: boolean
          minimum_cents_monthly: number
          minimum_cents_onetime: number
          name: string
          no_recurring: boolean
          requires_shipping: boolean
          sort_order: number
          static_id: string | null
          station_id: string
          tags: string[]
          updated_at: string
        }
        Insert: {
          category?: string | null
          cogs_cents?: number
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          expires_at?: string | null
          fmv_cents?: number
          fulfillment_method?: string
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_exclusive?: boolean
          is_featured?: boolean
          is_hidden?: boolean
          minimum_cents_monthly?: number
          minimum_cents_onetime?: number
          name: string
          no_recurring?: boolean
          requires_shipping?: boolean
          sort_order?: number
          static_id?: string | null
          station_id: string
          tags?: string[]
          updated_at?: string
        }
        Update: {
          category?: string | null
          cogs_cents?: number
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          expires_at?: string | null
          fmv_cents?: number
          fulfillment_method?: string
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_exclusive?: boolean
          is_featured?: boolean
          is_hidden?: boolean
          minimum_cents_monthly?: number
          minimum_cents_onetime?: number
          name?: string
          no_recurring?: boolean
          requires_shipping?: boolean
          sort_order?: number
          static_id?: string | null
          station_id?: string
          tags?: string[]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "gifts_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      interactions: {
        Row: {
          campaign_id: string | null
          created_at: string
          direction: string
          donor_id: string
          duration_minutes: number | null
          followup_by: string | null
          followup_completed: boolean
          followup_completed_at: string | null
          gift_intent_id: string | null
          id: string
          interaction_type: string
          occurred_at: string
          requires_followup: boolean
          staff_user_id: string
          station_id: string
          subject: string | null
          summary: string
          witness_id: string | null
        }
        Insert: {
          campaign_id?: string | null
          created_at?: string
          direction?: string
          donor_id: string
          duration_minutes?: number | null
          followup_by?: string | null
          followup_completed?: boolean
          followup_completed_at?: string | null
          gift_intent_id?: string | null
          id?: string
          interaction_type: string
          occurred_at: string
          requires_followup?: boolean
          staff_user_id: string
          station_id: string
          subject?: string | null
          summary: string
          witness_id?: string | null
        }
        Update: {
          campaign_id?: string | null
          created_at?: string
          direction?: string
          donor_id?: string
          duration_minutes?: number | null
          followup_by?: string | null
          followup_completed?: boolean
          followup_completed_at?: string | null
          gift_intent_id?: string | null
          id?: string
          interaction_type?: string
          occurred_at?: string
          requires_followup?: boolean
          staff_user_id?: string
          station_id?: string
          subject?: string | null
          summary?: string
          witness_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "interactions_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_gift_intent_id_fkey"
            columns: ["gift_intent_id"]
            isOneToOne: false
            referencedRelation: "gift_intents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_staff_user_id_fkey"
            columns: ["staff_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_witness_id_fkey"
            columns: ["witness_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      invites: {
        Row: {
          created_at: string
          deleted_at: string | null
          email: string
          expires_at: string
          id: string
          invited_by: string
          role: string
          station_id: string
          token: string
          used_at: string | null
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          email: string
          expires_at: string
          id?: string
          invited_by: string
          role?: string
          station_id: string
          token: string
          used_at?: string | null
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          email?: string
          expires_at?: string
          id?: string
          invited_by?: string
          role?: string
          station_id?: string
          token?: string
          used_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "invites_invited_by_fkey"
            columns: ["invited_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invites_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      match_allocations: {
        Row: {
          allocated_at: string
          allocated_by: string | null
          amount_cents: number
          created_at: string
          donation_id: string
          id: string
          match_pool_id: string
        }
        Insert: {
          allocated_at?: string
          allocated_by?: string | null
          amount_cents: number
          created_at?: string
          donation_id: string
          id?: string
          match_pool_id: string
        }
        Update: {
          allocated_at?: string
          allocated_by?: string | null
          amount_cents?: number
          created_at?: string
          donation_id?: string
          id?: string
          match_pool_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "match_allocations_allocated_by_fkey"
            columns: ["allocated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "match_allocations_donation_id_fkey"
            columns: ["donation_id"]
            isOneToOne: false
            referencedRelation: "donations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "match_allocations_match_pool_id_fkey"
            columns: ["match_pool_id"]
            isOneToOne: false
            referencedRelation: "match_pools"
            referencedColumns: ["id"]
          },
        ]
      }
      match_pools: {
        Row: {
          campaign_id: string | null
          created_at: string
          deleted_at: string | null
          description: string | null
          eligibility_rules: Json
          exhausted_at: string | null
          id: string
          is_active: boolean
          is_public: boolean
          match_ratio: number
          matcher_name: string | null
          matcher_type: string
          name: string
          remaining_cents: number
          station_id: string
          total_cents: number
          updated_at: string
          valid_from: string | null
          valid_until: string | null
        }
        Insert: {
          campaign_id?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          eligibility_rules?: Json
          exhausted_at?: string | null
          id?: string
          is_active?: boolean
          is_public?: boolean
          match_ratio?: number
          matcher_name?: string | null
          matcher_type?: string
          name: string
          remaining_cents: number
          station_id: string
          total_cents: number
          updated_at?: string
          valid_from?: string | null
          valid_until?: string | null
        }
        Update: {
          campaign_id?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          eligibility_rules?: Json
          exhausted_at?: string | null
          id?: string
          is_active?: boolean
          is_public?: boolean
          match_ratio?: number
          matcher_name?: string | null
          matcher_type?: string
          name?: string
          remaining_cents?: number
          station_id?: string
          total_cents?: number
          updated_at?: string
          valid_from?: string | null
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "match_pools_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "match_pools_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      memberships: {
        Row: {
          amount_cents: number
          cancelled_at: string | null
          created_at: string
          deleted_at: string | null
          donation_id: string | null
          donor_id: string
          ends_at: string | null
          id: string
          lapsed_at: string | null
          payment_failed_at: string | null
          payment_failures_count: number
          started_at: string
          station_id: string
          status: string
          stripe_subscription_id: string | null
          tier: string
          updated_at: string
        }
        Insert: {
          amount_cents: number
          cancelled_at?: string | null
          created_at?: string
          deleted_at?: string | null
          donation_id?: string | null
          donor_id: string
          ends_at?: string | null
          id?: string
          lapsed_at?: string | null
          payment_failed_at?: string | null
          payment_failures_count?: number
          started_at?: string
          station_id: string
          status?: string
          stripe_subscription_id?: string | null
          tier?: string
          updated_at?: string
        }
        Update: {
          amount_cents?: number
          cancelled_at?: string | null
          created_at?: string
          deleted_at?: string | null
          donation_id?: string | null
          donor_id?: string
          ends_at?: string | null
          id?: string
          lapsed_at?: string | null
          payment_failed_at?: string | null
          payment_failures_count?: number
          started_at?: string
          station_id?: string
          status?: string
          stripe_subscription_id?: string | null
          tier?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "memberships_donation_id_fkey"
            columns: ["donation_id"]
            isOneToOne: false
            referencedRelation: "donations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "memberships_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "memberships_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      operator_activity_log: {
        Row: {
          action: string
          created_at: string
          id: string
          ip_address: string | null
          metadata: Json
          operator_email: string
          operator_profile_id: string | null
          station_id: string
          user_agent: string | null
        }
        Insert: {
          action: string
          created_at?: string
          id?: string
          ip_address?: string | null
          metadata?: Json
          operator_email: string
          operator_profile_id?: string | null
          station_id: string
          user_agent?: string | null
        }
        Update: {
          action?: string
          created_at?: string
          id?: string
          ip_address?: string | null
          metadata?: Json
          operator_email?: string
          operator_profile_id?: string | null
          station_id?: string
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "operator_activity_log_operator_profile_id_fkey"
            columns: ["operator_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "operator_activity_log_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_intents: {
        Row: {
          amount_cents: number
          checkout_session_id: string | null
          created_at: string
          currency: string
          donation_id: string | null
          donor_id: string | null
          fee_coverage_cents: number
          id: string
          metadata: Json
          operator_id: string | null
          source_type: string
          station_id: string
          status: string
          stripe_payment_intent_id: string
          stripe_payment_method_id: string | null
          succeeded_at: string | null
          updated_at: string
        }
        Insert: {
          amount_cents: number
          checkout_session_id?: string | null
          created_at?: string
          currency?: string
          donation_id?: string | null
          donor_id?: string | null
          fee_coverage_cents?: number
          id?: string
          metadata?: Json
          operator_id?: string | null
          source_type?: string
          station_id: string
          status?: string
          stripe_payment_intent_id: string
          stripe_payment_method_id?: string | null
          succeeded_at?: string | null
          updated_at?: string
        }
        Update: {
          amount_cents?: number
          checkout_session_id?: string | null
          created_at?: string
          currency?: string
          donation_id?: string | null
          donor_id?: string | null
          fee_coverage_cents?: number
          id?: string
          metadata?: Json
          operator_id?: string | null
          source_type?: string
          station_id?: string
          status?: string
          stripe_payment_intent_id?: string
          stripe_payment_method_id?: string | null
          succeeded_at?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_intents_checkout_session_id_fkey"
            columns: ["checkout_session_id"]
            isOneToOne: false
            referencedRelation: "checkout_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_intents_donation_id_fkey"
            columns: ["donation_id"]
            isOneToOne: false
            referencedRelation: "donations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_intents_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_intents_operator_id_fkey"
            columns: ["operator_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_intents_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      press_passes: {
        Row: {
          created_at: string
          deleted_at: string | null
          expires_at: string
          holder_name: string
          id: string
          issued_at: string
          notes: string | null
          pass_number: string
          pass_type: string | null
          photo_url: string | null
          station_id: string
          status: string
          title: string | null
          updated_at: string
          verification_token: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          expires_at: string
          holder_name: string
          id?: string
          issued_at: string
          notes?: string | null
          pass_number: string
          pass_type?: string | null
          photo_url?: string | null
          station_id: string
          status?: string
          title?: string | null
          updated_at?: string
          verification_token: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          expires_at?: string
          holder_name?: string
          id?: string
          issued_at?: string
          notes?: string | null
          pass_number?: string
          pass_type?: string | null
          photo_url?: string | null
          station_id?: string
          status?: string
          title?: string | null
          updated_at?: string
          verification_token?: string
        }
        Relationships: [
          {
            foreignKeyName: "press_passes_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          allow_external_domain: boolean
          avatar_url: string | null
          created_at: string
          deleted_at: string | null
          display_name: string | null
          donor_id: string | null
          email: string
          id: string
          is_active: boolean
          last_login_at: string | null
          phone: string | null
          requires_2fa: boolean
          role: string
          station_id: string | null
          updated_at: string
        }
        Insert: {
          allow_external_domain?: boolean
          avatar_url?: string | null
          created_at?: string
          deleted_at?: string | null
          display_name?: string | null
          donor_id?: string | null
          email: string
          id: string
          is_active?: boolean
          last_login_at?: string | null
          phone?: string | null
          requires_2fa?: boolean
          role?: string
          station_id?: string | null
          updated_at?: string
        }
        Update: {
          allow_external_domain?: boolean
          avatar_url?: string | null
          created_at?: string
          deleted_at?: string | null
          display_name?: string | null
          donor_id?: string | null
          email?: string
          id?: string
          is_active?: boolean
          last_login_at?: string | null
          phone?: string | null
          requires_2fa?: boolean
          role?: string
          station_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      program_categories: {
        Row: {
          created_at: string
          deleted_at: string | null
          id: string
          is_active: boolean
          name: string
          slug: string
          sort_order: number
          station_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_active?: boolean
          name: string
          slug: string
          sort_order?: number
          station_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_active?: boolean
          name?: string
          slug?: string
          sort_order?: number
          station_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "program_categories_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      program_host_assignments: {
        Row: {
          created_at: string
          host_id: string
          id: string
          is_primary: boolean
          program_id: string
        }
        Insert: {
          created_at?: string
          host_id: string
          id?: string
          is_primary?: boolean
          program_id: string
        }
        Update: {
          created_at?: string
          host_id?: string
          id?: string
          is_primary?: boolean
          program_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "program_host_assignments_host_id_fkey"
            columns: ["host_id"]
            isOneToOne: false
            referencedRelation: "program_hosts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "program_host_assignments_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      program_hosts: {
        Row: {
          bio: string | null
          created_at: string
          deleted_at: string | null
          id: string
          is_active: boolean
          name: string
          photo_url: string | null
          slug: string
          station_id: string
          updated_at: string
        }
        Insert: {
          bio?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_active?: boolean
          name: string
          photo_url?: string | null
          slug: string
          station_id: string
          updated_at?: string
        }
        Update: {
          bio?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_active?: boolean
          name?: string
          photo_url?: string | null
          slug?: string
          station_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "program_hosts_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      program_schedule: {
        Row: {
          created_at: string
          day_of_week: number
          duration_minutes: number
          end_time: string
          id: string
          is_regular: boolean
          notes: string | null
          program_id: string
          start_time: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          day_of_week: number
          duration_minutes: number
          end_time: string
          id?: string
          is_regular?: boolean
          notes?: string | null
          program_id: string
          start_time: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          day_of_week?: number
          duration_minutes?: number
          end_time?: string
          id?: string
          is_regular?: boolean
          notes?: string | null
          program_id?: string
          start_time?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "program_schedule_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      programs: {
        Row: {
          category_id: string | null
          created_at: string
          deleted_at: string | null
          description: string | null
          external_id: string | null
          external_source: string | null
          id: string
          is_active: boolean
          name: string
          notes: string | null
          slug: string
          sort_order: number
          station_id: string
          updated_at: string
          website_url: string | null
        }
        Insert: {
          category_id?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          external_id?: string | null
          external_source?: string | null
          id?: string
          is_active?: boolean
          name: string
          notes?: string | null
          slug: string
          sort_order?: number
          station_id: string
          updated_at?: string
          website_url?: string | null
        }
        Update: {
          category_id?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          external_id?: string | null
          external_source?: string | null
          id?: string
          is_active?: boolean
          name?: string
          notes?: string | null
          slug?: string
          sort_order?: number
          station_id?: string
          updated_at?: string
          website_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "programs_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "program_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "programs_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      promo_codes: {
        Row: {
          applicable_ticket_type_ids: string[] | null
          code: string
          created_at: string
          deleted_at: string | null
          discount_cents: number | null
          discount_percent: number | null
          discount_type: string
          event_id: string | null
          id: string
          is_active: boolean
          max_uses: number | null
          max_uses_per_donor: number | null
          min_purchase_cents: number | null
          station_id: string
          times_used: number
          updated_at: string
          valid_from: string | null
          valid_until: string | null
        }
        Insert: {
          applicable_ticket_type_ids?: string[] | null
          code: string
          created_at?: string
          deleted_at?: string | null
          discount_cents?: number | null
          discount_percent?: number | null
          discount_type: string
          event_id?: string | null
          id?: string
          is_active?: boolean
          max_uses?: number | null
          max_uses_per_donor?: number | null
          min_purchase_cents?: number | null
          station_id: string
          times_used?: number
          updated_at?: string
          valid_from?: string | null
          valid_until?: string | null
        }
        Update: {
          applicable_ticket_type_ids?: string[] | null
          code?: string
          created_at?: string
          deleted_at?: string | null
          discount_cents?: number | null
          discount_percent?: number | null
          discount_type?: string
          event_id?: string | null
          id?: string
          is_active?: boolean
          max_uses?: number | null
          max_uses_per_donor?: number | null
          min_purchase_cents?: number | null
          station_id?: string
          times_used?: number
          updated_at?: string
          valid_from?: string | null
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "promo_codes_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "promo_codes_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      shows: {
        Row: {
          created_at: string
          deleted_at: string | null
          description: string | null
          host_name: string | null
          id: string
          is_active: boolean
          name: string
          slug: string
          station_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          host_name?: string | null
          id?: string
          is_active?: boolean
          name: string
          slug: string
          station_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          host_name?: string | null
          id?: string
          is_active?: boolean
          name?: string
          slug?: string
          station_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shows_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      station_sequences: {
        Row: {
          created_at: string
          current_value: number
          id: string
          sequence_year: number
          station_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          current_value?: number
          id?: string
          sequence_year: number
          station_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          current_value?: number
          id?: string
          sequence_year?: number
          station_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "station_sequences_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      stations: {
        Row: {
          call_sign: string
          code: string
          created_at: string
          deleted_at: string | null
          id: string
          name: string
          timezone: string
          updated_at: string
          website_url: string | null
        }
        Insert: {
          call_sign: string
          code: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          name: string
          timezone?: string
          updated_at?: string
          website_url?: string | null
        }
        Update: {
          call_sign?: string
          code?: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          name?: string
          timezone?: string
          updated_at?: string
          website_url?: string | null
        }
        Relationships: []
      }
      system_events: {
        Row: {
          attempts: number
          created_at: string
          error_message: string | null
          event_type: string
          id: string
          idempotency_key: string
          payload: Json | null
          payload_summary: string | null
          processed_at: string | null
          source: string
          status: string
        }
        Insert: {
          attempts?: number
          created_at?: string
          error_message?: string | null
          event_type: string
          id?: string
          idempotency_key: string
          payload?: Json | null
          payload_summary?: string | null
          processed_at?: string | null
          source: string
          status?: string
        }
        Update: {
          attempts?: number
          created_at?: string
          error_message?: string | null
          event_type?: string
          id?: string
          idempotency_key?: string
          payload?: Json | null
          payload_summary?: string | null
          processed_at?: string | null
          source?: string
          status?: string
        }
        Relationships: []
      }
      tax_documents: {
        Row: {
          created_at: string
          deductible_cents: number
          document_type: string
          donation_id: string
          donor_id: string
          fmv_cents: number
          generated_at: string
          gross_amount_cents: number
          id: string
          receipt_number: string | null
          snapshot_json: Json
          station_id: string
          superseded_at: string | null
          supersedes_id: string | null
        }
        Insert: {
          created_at?: string
          deductible_cents: number
          document_type?: string
          donation_id: string
          donor_id: string
          fmv_cents?: number
          generated_at?: string
          gross_amount_cents: number
          id?: string
          receipt_number?: string | null
          snapshot_json: Json
          station_id: string
          superseded_at?: string | null
          supersedes_id?: string | null
        }
        Update: {
          created_at?: string
          deductible_cents?: number
          document_type?: string
          donation_id?: string
          donor_id?: string
          fmv_cents?: number
          generated_at?: string
          gross_amount_cents?: number
          id?: string
          receipt_number?: string | null
          snapshot_json?: Json
          station_id?: string
          superseded_at?: string | null
          supersedes_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "tax_documents_donation_id_fkey"
            columns: ["donation_id"]
            isOneToOne: false
            referencedRelation: "donations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tax_documents_donor_id_fkey"
            columns: ["donor_id"]
            isOneToOne: false
            referencedRelation: "donors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tax_documents_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tax_documents_supersedes_id_fkey"
            columns: ["supersedes_id"]
            isOneToOne: false
            referencedRelation: "tax_documents"
            referencedColumns: ["id"]
          },
        ]
      }
      ticket_types: {
        Row: {
          available_from: string | null
          available_until: string | null
          capacity: number | null
          created_at: string
          deleted_at: string | null
          description: string | null
          event_id: string
          fmv_cents: number
          id: string
          is_active: boolean
          is_sliding_scale: boolean
          max_price_cents: number | null
          min_price_cents: number | null
          name: string
          price_cents: number
          sort_order: number
          suggested_price_cents: number | null
          updated_at: string
        }
        Insert: {
          available_from?: string | null
          available_until?: string | null
          capacity?: number | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          event_id: string
          fmv_cents?: number
          id?: string
          is_active?: boolean
          is_sliding_scale?: boolean
          max_price_cents?: number | null
          min_price_cents?: number | null
          name: string
          price_cents?: number
          sort_order?: number
          suggested_price_cents?: number | null
          updated_at?: string
        }
        Update: {
          available_from?: string | null
          available_until?: string | null
          capacity?: number | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          event_id?: string
          fmv_cents?: number
          id?: string
          is_active?: boolean
          is_sliding_scale?: boolean
          max_price_cents?: number | null
          min_price_cents?: number | null
          name?: string
          price_cents?: number
          sort_order?: number
          suggested_price_cents?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "ticket_types_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
        ]
      }
      underwriters: {
        Row: {
          billing_city: string | null
          billing_country: string | null
          billing_postal: string | null
          billing_same_as_primary: boolean
          billing_state: string | null
          billing_street_1: string | null
          billing_street_2: string | null
          city: string | null
          contact_email: string | null
          contact_name: string | null
          contact_phone: string | null
          contact_title: string | null
          country: string | null
          created_at: string
          deleted_at: string | null
          id: string
          is_active: boolean
          legal_name: string | null
          name: string
          notes: string | null
          organization_type: string
          postal_code: string | null
          relationship_owner_id: string | null
          state: string | null
          station_id: string
          street_line_1: string | null
          street_line_2: string | null
          tax_id: string | null
          updated_at: string
        }
        Insert: {
          billing_city?: string | null
          billing_country?: string | null
          billing_postal?: string | null
          billing_same_as_primary?: boolean
          billing_state?: string | null
          billing_street_1?: string | null
          billing_street_2?: string | null
          city?: string | null
          contact_email?: string | null
          contact_name?: string | null
          contact_phone?: string | null
          contact_title?: string | null
          country?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_active?: boolean
          legal_name?: string | null
          name: string
          notes?: string | null
          organization_type?: string
          postal_code?: string | null
          relationship_owner_id?: string | null
          state?: string | null
          station_id: string
          street_line_1?: string | null
          street_line_2?: string | null
          tax_id?: string | null
          updated_at?: string
        }
        Update: {
          billing_city?: string | null
          billing_country?: string | null
          billing_postal?: string | null
          billing_same_as_primary?: boolean
          billing_state?: string | null
          billing_street_1?: string | null
          billing_street_2?: string | null
          city?: string | null
          contact_email?: string | null
          contact_name?: string | null
          contact_phone?: string | null
          contact_title?: string | null
          country?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_active?: boolean
          legal_name?: string | null
          name?: string
          notes?: string | null
          organization_type?: string
          postal_code?: string | null
          relationship_owner_id?: string | null
          state?: string | null
          station_id?: string
          street_line_1?: string | null
          street_line_2?: string | null
          tax_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "underwriters_relationship_owner_id_fkey"
            columns: ["relationship_owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "underwriters_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      underwriting_agreements: {
        Row: {
          auto_renew: boolean
          created_at: string
          deleted_at: string | null
          deliverables: Json
          description: string | null
          document_id: string | null
          ends_at: string
          id: string
          internal_notes: string | null
          name: string
          payment_schedule: string
          payment_terms_days: number
          renewal_notice_days: number | null
          signed_at: string | null
          starts_at: string
          station_id: string
          status: string
          total_value_cents: number
          underwriter_id: string
          updated_at: string
        }
        Insert: {
          auto_renew?: boolean
          created_at?: string
          deleted_at?: string | null
          deliverables?: Json
          description?: string | null
          document_id?: string | null
          ends_at: string
          id?: string
          internal_notes?: string | null
          name: string
          payment_schedule?: string
          payment_terms_days?: number
          renewal_notice_days?: number | null
          signed_at?: string | null
          starts_at: string
          station_id: string
          status?: string
          total_value_cents: number
          underwriter_id: string
          updated_at?: string
        }
        Update: {
          auto_renew?: boolean
          created_at?: string
          deleted_at?: string | null
          deliverables?: Json
          description?: string | null
          document_id?: string | null
          ends_at?: string
          id?: string
          internal_notes?: string | null
          name?: string
          payment_schedule?: string
          payment_terms_days?: number
          renewal_notice_days?: number | null
          signed_at?: string | null
          starts_at?: string
          station_id?: string
          status?: string
          total_value_cents?: number
          underwriter_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "underwriting_agreements_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "underwriting_agreements_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "underwriting_agreements_underwriter_id_fkey"
            columns: ["underwriter_id"]
            isOneToOne: false
            referencedRelation: "underwriters"
            referencedColumns: ["id"]
          },
        ]
      }
      underwriting_broadcasts: {
        Row: {
          actual_duration_seconds: number | null
          agreement_id: string
          aired_at: string | null
          copy_approved: boolean
          copy_approved_at: string | null
          copy_approved_by: string | null
          copy_text: string | null
          created_at: string
          id: string
          notes: string | null
          scheduled_at: string
          scheduled_duration_seconds: number
          show_id: string | null
          station_id: string
          status: string
          updated_at: string
        }
        Insert: {
          actual_duration_seconds?: number | null
          agreement_id: string
          aired_at?: string | null
          copy_approved?: boolean
          copy_approved_at?: string | null
          copy_approved_by?: string | null
          copy_text?: string | null
          created_at?: string
          id?: string
          notes?: string | null
          scheduled_at: string
          scheduled_duration_seconds?: number
          show_id?: string | null
          station_id: string
          status?: string
          updated_at?: string
        }
        Update: {
          actual_duration_seconds?: number | null
          agreement_id?: string
          aired_at?: string | null
          copy_approved?: boolean
          copy_approved_at?: string | null
          copy_approved_by?: string | null
          copy_text?: string | null
          created_at?: string
          id?: string
          notes?: string | null
          scheduled_at?: string
          scheduled_duration_seconds?: number
          show_id?: string | null
          station_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "underwriting_broadcasts_agreement_id_fkey"
            columns: ["agreement_id"]
            isOneToOne: false
            referencedRelation: "underwriting_agreements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "underwriting_broadcasts_copy_approved_by_fkey"
            columns: ["copy_approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "underwriting_broadcasts_show_id_fkey"
            columns: ["show_id"]
            isOneToOne: false
            referencedRelation: "shows"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "underwriting_broadcasts_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
        ]
      }
      underwriting_invoices: {
        Row: {
          agreement_id: string
          created_at: string
          deleted_at: string | null
          description: string | null
          due_date: string
          id: string
          internal_notes: string | null
          invoice_date: string
          invoice_number: string
          line_items: Json
          notes: string | null
          paid_amount_cents: number | null
          paid_at: string | null
          payment_method: string | null
          payment_reference: string | null
          period_end: string | null
          period_start: string | null
          reminder_sent_at: string | null
          reminders_count: number
          sent_at: string | null
          station_id: string
          status: string
          subtotal_cents: number
          tax_cents: number
          total_cents: number
          underwriter_id: string
          updated_at: string
        }
        Insert: {
          agreement_id: string
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          due_date: string
          id?: string
          internal_notes?: string | null
          invoice_date: string
          invoice_number: string
          line_items?: Json
          notes?: string | null
          paid_amount_cents?: number | null
          paid_at?: string | null
          payment_method?: string | null
          payment_reference?: string | null
          period_end?: string | null
          period_start?: string | null
          reminder_sent_at?: string | null
          reminders_count?: number
          sent_at?: string | null
          station_id: string
          status?: string
          subtotal_cents: number
          tax_cents?: number
          total_cents: number
          underwriter_id: string
          updated_at?: string
        }
        Update: {
          agreement_id?: string
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          due_date?: string
          id?: string
          internal_notes?: string | null
          invoice_date?: string
          invoice_number?: string
          line_items?: Json
          notes?: string | null
          paid_amount_cents?: number | null
          paid_at?: string | null
          payment_method?: string | null
          payment_reference?: string | null
          period_end?: string | null
          period_start?: string | null
          reminder_sent_at?: string | null
          reminders_count?: number
          sent_at?: string | null
          station_id?: string
          status?: string
          subtotal_cents?: number
          tax_cents?: number
          total_cents?: number
          underwriter_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "underwriting_invoices_agreement_id_fkey"
            columns: ["agreement_id"]
            isOneToOne: false
            referencedRelation: "underwriting_agreements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "underwriting_invoices_station_id_fkey"
            columns: ["station_id"]
            isOneToOne: false
            referencedRelation: "stations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "underwriting_invoices_underwriter_id_fkey"
            columns: ["underwriter_id"]
            isOneToOne: false
            referencedRelation: "underwriters"
            referencedColumns: ["id"]
          },
        ]
      }
      verification_logs: {
        Row: {
          created_at: string
          id: string
          ip_address: unknown
          lookup_result: string
          lookup_type: string
          lookup_value: string
          press_pass_id: string | null
          user_agent: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          ip_address?: unknown
          lookup_result: string
          lookup_type: string
          lookup_value: string
          press_pass_id?: string | null
          user_agent?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          ip_address?: unknown
          lookup_result?: string
          lookup_type?: string
          lookup_value?: string
          press_pass_id?: string | null
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "verification_logs_press_pass_id_fkey"
            columns: ["press_pass_id"]
            isOneToOne: false
            referencedRelation: "press_passes"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      generate_receipt_number: {
        Args: { p_station_id: string }
        Returns: string
      }
      get_current_program: {
        Args: { p_station_code: string }
        Returns: {
          end_time: string
          minutes_remaining: number
          program_id: string
          program_name: string
          program_slug: string
          start_time: string
        }[]
      }
      get_current_user_profile: {
        Args: never
        Returns: {
          id: string
          is_active: boolean
          role: string
          station_id: string
        }[]
      }
      search_donors_fuzzy: {
        Args: { p_limit?: number; p_query: string; p_station_id: string }
        Returns: {
          created_at: string
          email: string
          first_name: string
          id: string
          last_name: string
          match_level: number
          match_score: number
          phone: string
        }[]
      }
      show_limit: { Args: never; Returns: number }
      show_trgm: { Args: { "": string }; Returns: string[] }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
