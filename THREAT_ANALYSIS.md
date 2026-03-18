# Threat Analysis and Risk Assessment - CardTone

**Date:** 2026-02-06
**Target:** CardTone Application Ecosystem (Parent App, Kid App, Backend)
**Assessor:** Antigravity AI

---

## 1. Executive Summary

This assessment has identified **CRITICAL** security vulnerabilities in the current CardTone architecture. The application currently operates with **zero effective authentication or authorization controls** on its backend.

**Bottom Line:** In its current state, the application is **unsafe for production**. Anyone with the API keys (which are embedded in the app) can read, modify, or delete *all* user data, control any kid's device, and bypass kiosk protections.

---

## 2. Architecture Overview

-   **Frontend:** Flutter Mobile Apps (Parent & Kid).
-   **Backend:** Supabase (PostgreSQL + Realtime).
-   **Authentication:** **None / Client-side only.** The app asks for Name/Email but does not verify them. It likely uses these to generate or lookup an ID in an open table.
-   **Authorization:** **None.** Database Row Level Security (RLS) policies are explicitly set to `using (true)`, allowing full public access.
-   **Communication:** REST API & Realtime WebSockets over HTTPS.

---

## 3. Asset Identification

| Asset | Description | Sensitivity |
| :--- | :--- | :--- |
| **Kid Profile Data** | Names, photos, linked parents. | **High (PII & Minor Safety)** |
| **Device Control** | Capability to play/stop media, lock device. | **High** |
| **Kiosk PIN** | The PIN code to exit kiosk mode. | **High** |
| **Activity Logs** | Detailed history of what the child watched/listened to. | **Medium-High (Privacy)** |
| **User Base** | The list of all parents and emails. | **Medium (Spam/Phishing risk)** |

---

## 4. Vulnerability Analysis

### 🚨 V1: Broken Access Control (Critical)
**Description:** The Supabase Row Level Security (RLS) policies are configured to allow `public` access to `all` tables for `all` operations (SELECT, INSERT, UPDATE, DELETE).
**Evidence:** `SUPABASE_SETUP.md`:
```sql
create policy "Public access" on parents for all using (true);
create policy "Public access" on kids for all using (true);
```
**Impact:**
-   **Total Data Compromise:** An attacker can download the entire `parents` and `kids` tables.
-   **Data Destruction:** An attacker can run a script to delete all users and settings.
-   **Account Takeover:** An attacker can overwrite the `linked_parents` array to add themselves as a parent to any kid, gaining control of that child's device.

### 🚨 V2: Absent Authentication (Critical)
**Description:** The "Login" screen (`LoginScreen.dart`) only accepts user input without verifying credentials against a secure identity provider. Checks are likely done by querying the open database.
**Impact:**
-   **Impersonation:** An attacker can "log in" as any user if they know (or guess) the email address.
-   **Spoofing:** Fake accounts and data can be flooded into the system.

### ⚠️ V3: Sensitive Data Exposure (High)
**Description:**
1.  **Kiosk PIN:** Stored as generic text (`kiosk_pin text`) in the `kids` table.
2.  **API Keys:** Supabase URL and Anon Key are hardcoded in `sync_service.dart`. While Anon Keys are designed to be public *if* RLS is secure, the combination of Open RLS + Public Key is catastrophic.
**Impact:**
-   **Kiosk Bypass:** A savvy kid or attacker can query the API to read the plaintext PIN and unlock the device.

### ⚠️ V4: Remote Command Injection (High)
**Description:** The `commands` table is writable by the public.
**Impact:**
-   **Denial of Service:** An attacker can continuously insert "STOP" commands into the table for a target kid ID, rendering the app unusable.

### ⚠️ V5: Client-Side Logic Enforcement (Medium)
**Description:** Critical logic like "Unlinking a kid" or "Checking permissions" is performed in the Dart code *after* fetching data.
**Impact:**
-   **Bypass:** An attacker using `curl` or a custom script can interact with the API directly, ignoring all client-side checks (e.g., they can delete a kid even if the client app says "Confirmation Required").

---

## 5. Risk Assessment Matrix

| Threat | Likelihood | Impact | Risk Level |
| :--- | :--- | :--- | :--- |
| **Unauthorized Access to Kid Data** | **Certain** (Public API) | **Critical** (Privacy violation) | **CRITICAL** |
| **Malicious Remote Control of Device** | **High** | **High** (Harassment/DoS) | **HIGH** |
| **Database Wipe** | **High** | **Critical** (Service loss) | **HIGH** |
| **Kiosk Mode Escape** | **Medium** | **Medium** | **MEDIUM** |

---

## 6. Recommendations & Remediation Plan

### Immediate Actions (Before ANY Release)
1.  **Implement Supabase Auth:**
    -   Replace the "Name/Email" screen with `Supabase.auth.signUp()` / `signInWithPassword()`.
    -   Generate User IDs (UIDs) securely via the Auth service, not the client.

2.  **Enable Strict RLS Policies:**
    -   **Parents:** Users can only view/edit *their own* row. `auth.uid() == id`.
    -   **Kids:** Users can only view/edit kids where their ID is in the `linked_parents` array.
    -   **Commands:** Only linked parents can `INSERT`; only the specific kid device can `UPDATE` (mark as executed).

3.  **Secure the Kiosk PIN:**
    -   Hash the PIN on the server side or client side before storage (e.g., bcrypt), OR rely on Supabase Auth for sensitive actions instead of a simple PIN.

4.  **Backend Logic (Edge Functions):**
    -   Move critical logic (like unlinking/deleting a kid) to Supabase Edge Functions (Postgres Functions). Do not trust the client to perform cascading deletes or permission checks.

### Long Term
1.  **Audit Logs:** Ensure `activity_logs` cannot be deleted even by the user, to preserve a trail in case of incidents.
2.  **API Key Rotation:** Rotate the Supabase keys after fixing RLS.

---
**Status:** 🔴 **FAILED** (Security Standards)
