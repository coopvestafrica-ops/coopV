/**
 * Models Index
 * 
 * Export all models from a single entry point
 */

const Referral = require('./Referral');
const User = require('./User');
const AuditLog = require('./AuditLog');
const LoanQR = require('./LoanQR');
const Ticket = require('./Ticket');
const TicketMessage = require('./TicketMessage');
const TicketAttachment = require('./TicketAttachment');

module.exports = {
  Referral,
  User,
  AuditLog,
  LoanQR,
  Ticket,
  TicketMessage,
  TicketAttachment
};
