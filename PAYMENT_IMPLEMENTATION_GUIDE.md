# Payment Implementation Guide

## Overview
The payment functionality has been implemented to save payment data to the database when users make contributions through the Dues Screen.

## How It Works

### 1. **Database Schema**
The payments are stored in the `contributions` table with the following structure:
```sql
CREATE TABLE public.contributions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    description TEXT,
    contribution_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. **Payment Flow**
1. User clicks on "Total Months" card in Home Screen
2. Opens Dues Screen showing all groups and their monthly contributions
3. User clicks "Pay" button for a specific group
4. Confirmation dialog appears
5. Upon confirmation, a contribution record is created and saved to database
6. Success message is shown and home screen is refreshed

### 3. **Code Implementation**

#### **Updated Files:**

**`lib/models/contribution.dart`**
- Updated `toJson()` method to map to database schema (snake_case)
- Added `toAppJson()` for app-level compatibility
- Enhanced `fromJson()` to handle both database and app JSON formats

**`lib/screens/dues/dues_screen.dart`**
- Implemented `_makePayment()` method to save payments to database
- Added confirmation dialog before payment
- Creates contribution record with proper mapping
- Shows success/error messages
- Added callback mechanism to refresh parent screen

**`lib/screens/home/home_screen.dart`**
- Updated stat card to be clickable
- Changed from "My Dues" to "Total Months"
- Added navigation to Dues Screen with callback

### 4. **Data Mapping**

**App Model → Database:**
- `groupId` → `group_id`
- `userId` → `user_id` 
- `amount` → `amount`
- `period` → `description`
- `dueDate` → `contribution_date`
- Database auto-generates: `id`, `created_at`, `updated_at`

### 5. **Payment Record Details**
When a payment is made, the following data is saved:
- **Group ID**: The group for which payment is made
- **User ID**: The current logged-in user
- **Amount**: Monthly contribution amount from the group
- **Description**: Current month/year (e.g., "September 2025")
- **Contribution Date**: First day of current month
- **Created At**: Timestamp when payment was recorded

### 6. **Features**
- ✅ Confirmation dialog before payment
- ✅ Database persistence of payment records
- ✅ Success/error feedback to user
- ✅ Auto-refresh of home screen after payment
- ✅ Proper error handling
- ✅ Loading states during payment processing

### 7. **Usage**
1. Navigate to Home Screen
2. Click on "Total Months" card
3. View all your groups and their contribution details
4. Click "Pay ₹XXX" button for any group
5. Confirm the payment in the dialog
6. Payment is recorded in database and success message is shown

### 8. **Database Query**
To view all payments made by a user:
```sql
SELECT * FROM public.contributions 
WHERE user_id = 'user-uuid-here' 
ORDER BY created_at DESC;
```

### 9. **Future Enhancements**
- Add payment history view
- Implement payment status tracking
- Add payment reminders
- Support for partial payments
- Integration with actual payment gateways
