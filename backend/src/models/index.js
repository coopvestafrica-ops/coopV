/**
 * Models Index
 * 
 * Export all models from a single entry point
 */

const Referral = require('./Referral');
const User = require('./User');
const AuditLog = require('./AuditLog');
const Loan = require('./Loan');
const LoanQR = require('./LoanQR');
const Ticket = require('./Ticket');
const TicketMessage = require('./TicketMessage');
const TicketAttachment = require('./TicketAttachment');
const Wallet = require('./Wallet');

module.exports = {
  Referral,
  User,
  AuditLog,
  Loan,
  LoanQR,
  Ticket,
  TicketMessage,
  TicketAttachment,
  Wallet
};
