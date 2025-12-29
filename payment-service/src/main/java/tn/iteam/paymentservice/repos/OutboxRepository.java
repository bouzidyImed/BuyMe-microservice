package tn.iteam.paymentservice.repos;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import tn.iteam.paymentservice.model.OutboxEvent;

import jakarta.persistence.LockModeType;
import java.util.List;

@Repository
public interface OutboxRepository extends JpaRepository<OutboxEvent, String> {

    // Fetch all pending events ordered by creation time
    List<OutboxEvent> findByStatusOrderByCreatedAtAsc(String status);

    // Fetch and lock oldest pending events for processing
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from OutboxEvent o where o.status = :status order by o.createdAt asc")
    List<OutboxEvent> fetchAndLockOldest(@Param("status") String status);

    // Optional: fetch a specific event by ID and lock it
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from OutboxEvent o where o.eventId = :eventId")
    OutboxEvent lockByEventId(@Param("eventId") String eventId);

    // Optional: fetch top N events for batch processing
    List<OutboxEvent> findTop100ByStatusOrderByCreatedAtAsc(String status);
}
